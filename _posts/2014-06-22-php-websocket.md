---
layout: post
title:  "php 实现的一个socket"
categories: php
tag: php
---
---
websocket服务类
Author: dun  time：2014-06-22

```
class Socket
{

    private $debug;
    private $master;                //主连接资源
    private $sockets = [];        //子连接资源


    /**
     * Socket constructor.
     * @param $address
     * @param $port
     * @param bool $debug
     */
    public function __construct($address, $port, $debug = TRUE)
    {
        if (substr(php_sapi_name(), 0, 3) !== 'cli')
            die("请通过命令行模式运行!");
        error_reporting(E_ALL);
        set_time_limit(0);
        ob_implicit_flush();
        $this->debug = $debug;
        $this->bind($address, $port);
    }

    /**
     * 监听端口
     * @param $address
     * @param $port
     */
    public function bind(&$address, &$port)
    {
        $this->master = socket_create(AF_INET, SOCK_STREAM, SOL_TCP);

        socket_set_option($this->master, SOL_SOCKET, SO_REUSEADDR, 1);

        if (@socket_bind($this->master, $address, $port)){
            !$this->debug || $this->log('开始监听: ' . $address . ':' . $port);
        }else {
            $this->getError($this->master);
        }
        socket_listen($this->master);

        $this->sockets = array('s' => $this->master);
    }

    /**
     * socket进入处理回调
     * @param $client
     */
    protected function In(&$client)
    {

    }

    /**
     * socket握手头信息回调
     * @param $client
     * @param $buffer
     * @return string
     */
    private function Hand(&$client, &$buffer)
    {
        $buf = substr($buffer, strpos($buffer, 'Sec-WebSocket-Key:') + 18);
        $key = trim(substr($buf, 0, strpos($buf, "\r\n")));
        $new_key = base64_encode(sha1($key . "258EAFA5-E914-47DA-95CA-C5AB0DC85B11", true));
        $hand = "HTTP/1.1 101 Switching Protocols\r\n";
        $hand .= "Upgrade: websocket\r\n";
        $hand .= "Sec-WebSocket-Version: 13\r\n";
        $hand .= "Connection: Upgrade\r\n";
        $hand .= "Sec-WebSocket-Accept: " . $new_key . "\r\n\r\n";
        return $hand;
    }

    /**
     * 广播消息回调
     * @param $keys
     * @return array
     */
    private function Push($keys)
    {
        $msg = array();
        foreach ($keys as $v) {
            if ($v != 's'){
                $msg[$v] = '广播消息';
            }
        }
        return $msg;
    }

    /**
     * socket消息处理回调
     * @param $client
     * @param $buffer
     * @return string
     */
    private function Msg(&$client, &$buffer)
    {
        return '';
    }

    /**
     * socket退出处理回调
     * @param $client
     * @param $buffer
     */
    private function Out(&$client, &$buffer)
    {

    }

    /**
     * socket编码
     * @param $msg
     * @return string
     */
    private function encode(&$msg)
    {
        $msg = preg_replace(array('/\r$/', '/\n$/', '/\r\n$/',), '', $msg);

        $frame[0] = '81';

        $len = strlen($msg);

        $frame[1] = $len < 16 ? '0' . dechex($len) : dechex($len);

        $l = strlen($msg);

        for ($i = 0; $i < $l; $i++) {
            @$frame[2] .= dechex(ord($msg{$i}));
        }
        return pack("H*", implode('', $frame));
    }

    /**
     * socket解码
     * @param $str
     * @return bool|string
     */
    private function decode(&$str)
    {
        $msg = unpack('H*', $str);
        $head = substr($msg[1], 0, 2);
        $data = '';
        if (hexdec($head{1}) === 8) {
            $data = false;
        } else if (hexdec($head{1}) === 1) {
            $mask[] = hexdec(substr($msg[1], 4, 2));
            $mask[] = hexdec(substr($msg[1], 6, 2));
            $mask[] = hexdec(substr($msg[1], 8, 2));
            $mask[] = hexdec(substr($msg[1], 10, 2));
            $e = strlen($msg[1]) - 2;
            $n = 0;

            for ($i = 12; $i <= $e; $i += 2) {
                $data .= chr($mask[$n++ % 4] ^ hexdec(substr($msg[1], $i, 2)));
            }
        }
        return $data;
    }

    /**
     * 关闭某一个连接
     * @param $client
     */
    private function close(&$client)
    {
        socket_close($client);
        $k = array_search($client, $this->sockets);
        unset($this->sockets[$k]);
    }

    /**
     * 开始运行
     */
    public function run()
    {
        while (true) {
            $changes = $this->sockets;
            $num_changed = @socket_select($changes, $write = NULL, $except = NULL, 0);

            if (false === $num_changed) {
                $this->getError($this->master);
            } elseif ($num_changed === 0) {
                $broadcast = $this->Push(array_keys($this->sockets));

                if (!empty($broadcast)) continue;

                foreach ($broadcast as $key => $val) {
                    $msg = $this->encode($val);

                    socket_write($this->sockets[$key], $msg, strlen($msg));
                }
                continue;
            }
            foreach ($changes as $client) {
                if ($client == $this->master) {
                    !$this->debug || $this->log($client . '登陆！');

                    $newClient = socket_accept($this->master);

                    $this->sockets[] = $newClient;

                    $this->In($newClient);
                } else {
                    @$len = socket_recv($client, $buffer, 2048, 0);
                    if ($len < 7) {
                        !$this->debug || $this->log($client . '退出！');

                        $this->Out($client, $buffer);

                        $this->close($client);

                        continue;
                    }
                    $key = array_search($client, $this->sockets);

                    if (is_int($key)) {
                        !$this->debug || $this->log($client . '握手！');

                        $hand = $this->Hand($client, $buffer);

                        !$hand || socket_write($client, $hand, strlen($hand));

                        $this->sockets[$key . 'S'] = $this->sockets[$key];

                        unset($this->sockets[$key]);
                    } else {
                        !$this->debug || $this->log($client . '消息！');

                        $msg = $this->encode($this->Msg($client, $this->decode($buffer)));

                        !$msg || socket_write($client, $msg, strlen($msg));
                    }
                }
            }
        }
    }

    /**
     * 获取错误信息
     * @param $socket
     */
    private function getError(&$socket)
    {
        !$this->debug || $this->log('错误：' . socket_strerror(socket_last_error($socket)));
        socket_clear_error();
    }


    /**
     * 在终端输出调试信息
     * @param $t
     */
    protected function log($t)
    {
        fwrite(STDOUT, $t . "\r\n");
    }
}

$s = new Socket('127.0.0.1','12306');
$s->run();