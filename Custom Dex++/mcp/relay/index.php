<?php
// PHP 7.4+, JSON + writable private storage. No database required.
declare(strict_types=1);
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');
header('X-Content-Type-Options: nosniff');
function reply(int $status, array $body): void {
    http_response_code($status);
    echo json_encode($body, JSON_UNESCAPED_SLASHES | JSON_INVALID_UTF8_SUBSTITUTE);
    exit;
}
if ($_SERVER['REQUEST_METHOD'] !== 'POST') reply(405, ['error'=>'POST required']);
$raw=file_get_contents('php://input', false, null, 0, 524289);
if (strlen($raw)>524288) reply(413, ['error'=>'Payload too large']);
$input=json_decode($raw,true);
if (!is_array($input)) reply(400,['error'=>'Invalid JSON']);
$dir=getenv('DEX_RELAY_STORAGE') ?: sys_get_temp_dir().'/noky-dex-'.hash('sha256',__DIR__);
if (!is_dir($dir) && !mkdir($dir,0700,true) && !is_dir($dir)) reply(500,['error'=>'Storage unavailable']);
$action=$input['action'] ?? '';
if ($action==='pair') {
    // Rate limit creation per address. Do not trust forwarded headers.
    $rate=fopen($dir.'/rate-'.hash('sha256',$_SERVER['REMOTE_ADDR'] ?? ''),'c+');
    if (!$rate || !flock($rate,LOCK_EX)) reply(503,['error'=>'Storage busy']);
    $times=json_decode(stream_get_contents($rate),true) ?: [];
    $times=array_values(array_filter($times, function($t){return $t>time()-60;}));
    if (count($times)>=10) {fclose($rate); reply(429,['error'=>'Too many pair requests']);}
    $times[]=time(); rewind($rate); ftruncate($rate,0); fwrite($rate,json_encode($times)); fclose($rate);
    $code=strtoupper(bin2hex(random_bytes(16)));
    $secret=bin2hex(random_bytes(32));
    $session=['expires'=>time()+3600,'secret'=>hash('sha256',$secret),'lastSeen'=>time(),'commands'=>[],'jobs'=>[]];
    $file=$dir.'/session-'.hash('sha256',$code).'.json';
    $handle=fopen($file,'x');
    if (!$handle) reply(500,['error'=>'Cannot create session']);
    chmod($file,0600); fwrite($handle,json_encode($session)); fclose($handle);
    // Bounded housekeeping; storage should also have a scheduled expiration cleanup.
    $checked=0;
    foreach (new DirectoryIterator($dir) as $entry) {
        if (++$checked>500) break;
        if ($entry->isFile() && $entry->getMTime()<time()-7200) @unlink($entry->getPathname());
    }
    reply(200,['code'=>$code,'clientToken'=>$secret,'expiresIn'=>3600]);
}
$code=strtoupper(str_replace([' ','-'], '', (string)($input['code'] ?? '')));
if (!preg_match('/^[A-F0-9]{32}$/D',$code)) reply(401,['error'=>'Invalid session code']);
$file=$dir.'/session-'.hash('sha256',$code).'.json';
$handle=@fopen($file,'r+');
if (!$handle) reply(404,['error'=>'Session not found']);
if (!flock($handle,LOCK_EX)) reply(503,['error'=>'Session busy']);
$session=json_decode(stream_get_contents($handle),true);
if (!$session || $session['expires']<time()) {fclose($handle); @unlink($file); reply(410,['error'=>'Session expired']);}
$clientActions=['poll','result','close'];
if (in_array($action,$clientActions,true)) {
    if (!hash_equals($session['secret'],hash('sha256',(string)($input['clientToken'] ?? '')))) {
        fclose($handle); reply(401,['error'=>'Invalid client token']);
    }
}
foreach ($session['jobs'] as $id=>$job) {
    if ($job['created']<time()-60) unset($session['jobs'][$id]);
}
$session['commands']=array_values(array_filter($session['commands'],function($c) use ($session){return isset($session['jobs'][$c['id']]);}));
$out=[];
switch ($action) {
case 'status':
    $out=['connected'=>$session['lastSeen']>time()-10,'expires'=>$session['expires']]; break;
case 'call':
    if ($session['lastSeen']<time()-10) {fclose($handle); reply(409,['error'=>'Dex disconnected']);}
    if (!in_array($input['operation'] ?? '',['dex_children','dex_inspect','dex_set'],true)) {fclose($handle); reply(400,['error'=>'Unknown operation']);}
    if (count($session['jobs'])>=32) {fclose($handle); reply(429,['error'=>'Too many pending requests']);}
    $args=$input['arguments'] ?? null;
    if (!is_array($args)) {fclose($handle); reply(400,['error'=>'Invalid arguments']);}
    $id=bin2hex(random_bytes(12));
    $session['jobs'][$id]=['created'=>time(),'done'=>false];
    $session['commands'][]=['id'=>$id,'operation'=>$input['operation'],'arguments'=>$args];
    $out=['id'=>$id]; break;
case 'poll':
    $session['lastSeen']=time();
    $out=['commands'=>array_slice($session['commands'],0,8)];
    $session['commands']=array_slice($session['commands'],8); break;
case 'result':
    $id=(string)($input['id'] ?? '');
    if (isset($session['jobs'][$id])) {
        $session['jobs'][$id]['done']=true;
        $session['jobs'][$id]['response']=['ok'=>($input['ok'] ?? false)===true,'result'=>$input['result'] ?? null,'error'=>$input['error'] ?? null];
    }
    $out=['ok'=>true]; break;
case 'fetch':
    $id=(string)($input['id'] ?? '');
    $job=$session['jobs'][$id] ?? null;
    if (!$job) {fclose($handle); reply(404,['error'=>'Request expired or unknown']);}
    $out=['done'=>$job['done']];
    if ($job['done']) {$out['response']=$job['response']; unset($session['jobs'][$id]);}
    break;
case 'close':
    fclose($handle); @unlink($file); reply(200,['closed'=>true]); break;
default:
    fclose($handle); reply(400,['error'=>'Unknown action']);
}
rewind($handle); ftruncate($handle,0); fwrite($handle,json_encode($session)); fflush($handle); fclose($handle);
reply(200,$out);
