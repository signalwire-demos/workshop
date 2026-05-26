<?php
/**
 * Workshop AI Agent app — Pillar 1 (PHP).
 *
 * Front-controller: routes /, /shared/*, /demo.js, /api/setup, /api/wire-number,
 * /agent/*. Run with PHP's built-in server:
 *
 *   composer install
 *   php -S 0.0.0.0:8000 index.php
 */

declare(strict_types=1);

require_once __DIR__ . '/agent.php';

use SignalWire\REST\RestClient;

session_start();
$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH) ?? '/';
$sharedUi = realpath(__DIR__ . '/../../../../shared/ui');

function jsonResponse(int $status, array $body): void
{
    http_response_code($status);
    header('Content-Type: application/json');
    echo json_encode($body);
    exit;
}

// /shared/* — static assets
if (str_starts_with($path, '/shared/')) {
    $file = $sharedUi . substr($path, strlen('/shared'));
    if (!is_file($file)) { http_response_code(404); exit; }
    $ext = pathinfo($file, PATHINFO_EXTENSION);
    $ct = ['css' => 'text/css', 'js' => 'application/javascript', 'html' => 'text/html'][$ext] ?? 'application/octet-stream';
    header('Content-Type: ' . $ct);
    readfile($file);
    exit;
}

if ($path === '/') {
    header('Content-Type: text/html');
    readfile($sharedUi . '/creds-form.html');
    exit;
}

if ($path === '/demo.js') {
    header('Content-Type: application/javascript');
    readfile(__DIR__ . '/demo.js');
    exit;
}

if ($path === '/api/setup' && $_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true) ?? [];
    $projectId = trim($data['project_id'] ?? '');
    $space = trim($data['space'] ?? '');
    $token = trim($data['token'] ?? '');
    if (!$projectId || !$space || !$token) jsonResponse(400, ['ok' => false, 'error' => 'All fields required']);
    try {
        $client = new RestClient($projectId, $token, $space);
        $numbers = $client->phoneNumbers->list(['limit' => 20]);
    } catch (\Throwable $e) {
        jsonResponse(400, ['ok' => false, 'error' => 'Credential check failed: ' . $e->getMessage()]);
    }
    $_SESSION['creds'] = compact('projectId', 'space', 'token');
    jsonResponse(200, [
        'ok' => true, 'jwt' => '', 'subscriber_id' => '',
        'numbers' => $numbers, 'agent_path' => '/agent',
    ]);
}

if ($path === '/api/wire-number' && $_SERVER['REQUEST_METHOD'] === 'POST') {
    if (empty($_SESSION['creds'])) jsonResponse(400, ['ok' => false, 'error' => 'Run /api/setup first']);
    $data = json_decode(file_get_contents('php://input'), true) ?? [];
    $sid = trim($data['sid'] ?? '');
    $publicUrl = trim($data['public_url'] ?? '');
    if (!$sid || !$publicUrl) jsonResponse(400, ['ok' => false, 'error' => 'sid + public_url required']);
    $c = $_SESSION['creds'];
    try {
        $client = new RestClient($c['projectId'], $c['token'], $c['space']);
        $voiceUrl = rtrim($publicUrl, '/') . '/agent';
        $client->phoneNumbers->update($sid, ['voice_url' => $voiceUrl, 'voice_method' => 'POST']);
        jsonResponse(200, ['ok' => true, 'voice_url' => $voiceUrl]);
    } catch (\Throwable $e) {
        jsonResponse(400, ['ok' => false, 'error' => $e->getMessage()]);
    }
}

// /agent/* — route to AgentBase
if (str_starts_with($path, '/agent')) {
    $agent = new WorkshopAgent();
    // AgentBase doesn't expose a clean "handle this request" entry point in the
    // sandbox we're targeting; delegate via its handleRequest equivalent if
    // available, otherwise dispatch via the SDK's recommended pattern.
    if (method_exists($agent, 'handleRequest')) {
        $agent->handleRequest();
    } else {
        // Fallback: agent self-runs. This is sub-optimal for unified hosting;
        // in production you'd reverse-proxy /agent to a dedicated agent server.
        $agent->run();
    }
    exit;
}

http_response_code(404);
echo "Not found";
