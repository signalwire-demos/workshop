<?php
/**
 * Workshop RELAY realtime — Pillar 3 (PHP).
 *
 * ReactPHP HTTP + Ratchet WS on the same port (8002). Long-running PHP
 * process (so request-per-process PHP semantics don't apply).
 *
 *   composer install
 *   php server.php
 */

declare(strict_types=1);

require_once __DIR__ . '/vendor/autoload.php';

use Ratchet\MessageComponentInterface;
use Ratchet\ConnectionInterface;
use Ratchet\WebSocket\WsServer;
use Ratchet\Http\HttpServer;
use Ratchet\Http\Router;
use Ratchet\Server\IoServer;
use React\EventLoop\Loop;
use React\Http\Message\Response;
use SignalWire\REST\RestClient;
use SignalWire\Relay\Client as RelayClient;

$sharedUi = realpath(__DIR__ . '/../../../../shared/ui');

class EventBus implements MessageComponentInterface {
    /** @var \SplObjectStorage<ConnectionInterface, null> */
    public \SplObjectStorage $clients;
    public function __construct(public bool $relayReady = false) { $this->clients = new \SplObjectStorage; }
    public function onOpen(ConnectionInterface $conn): void {
        $this->clients->attach($conn);
        $conn->send(json_encode($this->relayReady
            ? ['kind' => 'system', 'message' => 'ws connected']
            : ['kind' => 'error', 'message' => 'Run setup first']));
    }
    public function onClose(ConnectionInterface $conn): void { $this->clients->detach($conn); }
    public function onError(ConnectionInterface $conn, \Exception $e): void { $conn->close(); }
    public function onMessage(ConnectionInterface $from, $msg): void { /* ignore client → server */ }
    public function broadcast(array $event): void {
        $json = json_encode($event);
        foreach ($this->clients as $c) { $c->send($json); }
    }
}

$state = ['creds' => null, 'relay' => null];
$bus = new EventBus();

$httpHandler = function (\Psr\Http\Message\ServerRequestInterface $req) use (&$state, &$bus, $sharedUi) {
    $path = $req->getUri()->getPath();
    if ($path === '/') {
        return new Response(200, ['Content-Type' => 'text/html'],
            file_get_contents("$sharedUi/creds-form.html"));
    }
    if ($path === '/demo.js') {
        return new Response(200, ['Content-Type' => 'application/javascript'],
            file_get_contents(__DIR__ . '/demo.js'));
    }
    if (str_starts_with($path, '/shared/')) {
        $file = $sharedUi . substr($path, 7);
        if (!is_file($file)) return new Response(404);
        $ext = pathinfo($file, PATHINFO_EXTENSION);
        $ct = ['css' => 'text/css', 'js' => 'application/javascript', 'html' => 'text/html'][$ext] ?? 'application/octet-stream';
        return new Response(200, ['Content-Type' => $ct], file_get_contents($file));
    }
    if ($path === '/api/setup' && $req->getMethod() === 'POST') {
        $data = json_decode((string) $req->getBody(), true) ?? [];
        $pid = trim($data['project_id'] ?? '');
        $sp = trim($data['space'] ?? '');
        $tk = trim($data['token'] ?? '');
        if (!$pid || !$sp || !$tk)
            return new Response(400, ['Content-Type' => 'application/json'], json_encode(['ok' => false, 'error' => 'All fields required']));
        try {
            (new RestClient($pid, $tk, $sp))->phoneNumbers->list(['limit' => 1]);
        } catch (\Throwable $e) {
            return new Response(400, ['Content-Type' => 'application/json'],
                json_encode(['ok' => false, 'error' => "Credential check failed: {$e->getMessage()}"]));
        }

        if ($state['relay']) {
            try { $state['relay']->disconnect(); } catch (\Throwable) {}
        }

        $rl = new RelayClient([
            'project' => $pid, 'token' => $tk, 'host' => $sp, 'contexts' => ['workshop'],
        ]);
        $rl->onCall(function ($call) use (&$bus) {
            $bus->broadcast(['kind' => 'call', 'state' => 'incoming', 'call_id' => $call->call_id]);
            try {
                $call->answer();
                $bus->broadcast(['kind' => 'call', 'state' => 'answered', 'call_id' => $call->call_id]);
            } catch (\Throwable $e) {
                $bus->broadcast(['kind' => 'error', 'message' => "answer failed: {$e->getMessage()}"]);
            }
        });

        Loop::futureTick(function () use ($rl, $bus) {
            try { $rl->connect(); $bus->broadcast(['kind' => 'system', 'message' => 'RELAY connected']); }
            catch (\Throwable $e) { $bus->broadcast(['kind' => 'error', 'message' => "RELAY connect failed: {$e->getMessage()}"]); }
        });

        $state['creds'] = ['projectId' => $pid, 'space' => $sp, 'token' => $tk];
        $state['relay'] = $rl;
        $bus->relayReady = true;
        return new Response(200, ['Content-Type' => 'application/json'],
            json_encode(['ok' => true, 'jwt' => 'session-validated', 'subscriber_id' => 'n/a']));
    }
    if ($path === '/api/dial' && $req->getMethod() === 'POST') {
        if (!$state['relay'])
            return new Response(400, ['Content-Type' => 'application/json'], json_encode(['ok' => false, 'error' => 'Run setup first']));
        $data = json_decode((string) $req->getBody(), true) ?? [];
        $from = trim($data['from'] ?? '');
        $to = trim($data['to'] ?? '');
        if (!$from || !$to)
            return new Response(400, ['Content-Type' => 'application/json'], json_encode(['ok' => false, 'error' => 'from + to required']));
        $devices = [[['type' => 'phone', 'from' => $from, 'to' => $to, 'timeout' => 30]]];
        try {
            $call = $state['relay']->dial($devices);
            return new Response(200, ['Content-Type' => 'application/json'],
                json_encode(['ok' => true, 'call_id' => $call->call_id]));
        } catch (\Throwable $e) {
            return new Response(400, ['Content-Type' => 'application/json'],
                json_encode(['ok' => false, 'error' => $e->getMessage()]));
        }
    }
    return new Response(404, [], 'Not found');
};

$loop = Loop::get();
$port = (int) ($_ENV['PORT'] ?? getenv('PORT') ?: 8002);

// HTTP server
$http = new \React\Http\HttpServer($httpHandler);
$socket = new \React\Socket\SocketServer("0.0.0.0:$port", [], $loop);
$http->listen($socket);

// WS server on the same port via a separate socket using Ratchet IoServer
// is awkward; in practice you'd either run WS on a sub-path with
// Ratchet's HttpServer route, or run it on a separate port. For workshop
// simplicity we expose WS on port+1.
$wsPort = $port + 1000;
$ws = new IoServer(new HttpServer(new WsServer($bus)),
    new \React\Socket\SocketServer("0.0.0.0:$wsPort", [], $loop), $loop);

echo "PHP RELAY realtime: HTTP on http://0.0.0.0:$port  /  WS on ws://0.0.0.0:$wsPort/ws/events\n";
echo "NOTE: demo.js expects /ws/events on the same port — adjust demo.js\n";
echo "      or front this with a reverse proxy that combines both.\n";
$loop->run();
