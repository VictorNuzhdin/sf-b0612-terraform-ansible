<html>
<head>
    <title>Test PHP</title>
</head>

<body>
    <?php 
        echo '<pre>' . PHP_EOL;
        echo 'It works!' . PHP_EOL;
        print '---------------------------------' . PHP_EOL;
        // Get Current Server DateTime
        date_default_timezone_set('Asia/Omsk');
        //$dt = date('Y-d-m h:i:s a', time());
        $dt = date('Y-d-m H:i:s', time());
        // Render output
        print 'Server time: ' . $dt . PHP_EOL;
        echo '</pre>' . PHP_EOL;
    ?>
</body>
</html>
