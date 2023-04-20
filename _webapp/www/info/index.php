<html>
<head>
    <title>Server Info</title>
</head>
<body>
<pre>
    SERVER_PHP_VERSION: <?php echo $_SERVER['PHP_VERSION'] . PHP_EOL;     /* 8.2.4 */ ?>
    SERVER_SOFTWARE...: <?php echo $_ENV['SERVER_SOFTWARE'] . PHP_EOL;    /* nginx/1.23.3 */ ?>
    SERVER_IP_ADDR....: <?php echo $_SERVER['SERVER_ADDR'] . PHP_EOL;     /* 10.100.11.3 */ ?>
    SERVER_PORT.......: <?php echo $_SERVER['SERVER_PORT'] . PHP_EOL;     /* 80 */ ?>
    SERVER_INTERFACE..: <?php echo $_ENV['GATEWAY_INTERFACE'] . PHP_EOL;  /* CGI/1.1 */ ?>
    ---
    CLIENT_GW_IP_ADDR: <?php echo $_SERVER['REMOTE_ADDR'] . PHP_EOL;      /* 192.168.230.1 */ ?>
    CLIENT_PORT......: <?php echo $_SERVER['REMOTE_PORT'] . PHP_EOL;      /* 49801 */ ?>
    CLIENT_BROWSER_ID: <?php echo $_ENV['HTTP_USER_AGENT'] . PHP_EOL;     /* Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36 */ ?>
</pre>
</body>
</html>
