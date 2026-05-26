<?php
/**
 * Workshop REST tour — Pillar 2 (PHP).
 *
 *   composer install
 *   php -S 0.0.0.0:8001 index.php
 */

declare(strict_types=1);

require_once __DIR__ . '/vendor/autoload.php';

use SignalWire\REST\RestClient;

session_start();
$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH) ?? '/';
$sharedUi = realpath(__DIR__ . '/../../../../shared/ui');

function jsonResponse(int $status, array $body): void {
    http_response_code($status);
    header('Content-Type: application/json');
    echo json_encode($body);
    exit;
}

function client(): RestClient {
    $c = $_SESSION['creds'] ?? null;
    if (!$c) jsonResponse(400, ['ok' => false, 'error' => 'Run setup first']);
    return new RestClient($c['projectId'], $c['token'], $c['space']);
}

if (str_starts_with($path, '/shared/')) {
    $file = $sharedUi . substr($path, strlen('/shared'));
    if (!is_file($file)) { http_response_code(404); exit; }
    $ext = pathinfo($file, PATHINFO_EXTENSION);
    $ct = ['css' => 'text/css', 'js' => 'application/javascript', 'html' => 'text/html'][$ext] ?? 'application/octet-stream';
    header('Content-Type: ' . $ct);
    readfile($file);
    exit;
}
if ($path === '/') { header('Content-Type: text/html'); readfile($sharedUi . '/creds-form.html'); exit; }
if ($path === '/demo.js') { header('Content-Type: application/javascript'); readfile(__DIR__ . '/demo.js'); exit; }

if ($path === '/api/setup' && $_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true) ?? [];
    $pid = trim($data['project_id'] ?? ''); $sp = trim($data['space'] ?? ''); $tk = trim($data['token'] ?? '');
    if (!$pid || !$sp || !$tk) jsonResponse(400, ['ok' => false, 'error' => 'All fields required']);
    try {
        (new RestClient($pid, $tk, $sp))->phoneNumbers->list(['limit' => 1]);
    } catch (\Throwable $e) {
        jsonResponse(400, ['ok' => false, 'error' => 'Credential check failed: ' . $e->getMessage()]);
    }
    $_SESSION['creds'] = ['projectId' => $pid, 'space' => $sp, 'token' => $tk];
    jsonResponse(200, ['ok' => true, 'jwt' => 'session-validated', 'subscriber_id' => 'n/a']);
}

if ($path === '/api/list-numbers') {
    try {
        $resp = client()->phoneNumbers->list(['limit' => 20]);
        jsonResponse(200, ['ok' => true, 'sdk_call' => '$client->phoneNumbers->list([\'limit\' => 20])', 'response' => $resp]);
    } catch (\Throwable $e) { jsonResponse(400, ['ok' => false, 'error' => $e->getMessage()]); }
}

if ($path === '/api/send-sms' && $_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true) ?? [];
    $from = trim($data['from'] ?? ''); $to = trim($data['to'] ?? '');
    $body = trim($data['body'] ?? 'Hello from the SignalWire workshop!');
    if (!$from || !$to) jsonResponse(400, ['ok' => false, 'error' => 'from + to required']);
    try {
        $resp = client()->compat->messages->create(['from' => $from, 'to' => $to, 'body' => $body]);
        jsonResponse(200, [
            'ok' => true,
            'sdk_call' => sprintf('$client->compat->messages->create([from=>%s, to=>%s, body=>...])', $from, $to),
            'response' => $resp,
        ]);
    } catch (\Throwable $e) { jsonResponse(400, ['ok' => false, 'error' => $e->getMessage()]); }
}

if ($path === '/api/recent-calls') {
    try {
        $resp = client()->compat->calls->list(['page_size' => 10]);
        jsonResponse(200, ['ok' => true, 'sdk_call' => '$client->compat->calls->list([\'page_size\' => 10])', 'response' => $resp]);
    } catch (\Throwable $e) { jsonResponse(400, ['ok' => false, 'error' => $e->getMessage()]); }
}

if ($path === '/api/wire-number' && $_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true) ?? [];
    $sid = trim($data['sid'] ?? ''); $voiceUrl = trim($data['voice_url'] ?? '');
    if (!$sid || !$voiceUrl) jsonResponse(400, ['ok' => false, 'error' => 'sid + voice_url required']);
    try {
        $resp = client()->phoneNumbers->update($sid, ['voice_url' => $voiceUrl, 'voice_method' => 'POST']);
        jsonResponse(200, [
            'ok' => true,
            'sdk_call' => sprintf('$client->phoneNumbers->update(%s, [voice_url=>%s])', $sid, $voiceUrl),
            'response' => $resp,
        ]);
    } catch (\Throwable $e) { jsonResponse(400, ['ok' => false, 'error' => $e->getMessage()]); }
}

http_response_code(404);
echo "Not found";
