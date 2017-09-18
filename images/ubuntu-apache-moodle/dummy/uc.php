<?php
/**
 * Dummy for website under construction
 * User: demmonico@gmail.com
 * Date: 31.08.17
 * Time: 15:35
 */

$status = is_file('./status') ? file_get_contents('./status') : '';
?>

<!DOCTYPE html>
<html>
<head>
    <title>Maintenance</title>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <style>
        h1 { font-size: 50px; }
        body { text-align:center; font: 20px Helvetica, sans-serif; color: #333; }
    </style>
</head>
<body>
<h1>Maintenance</h1>
<p>We apologize for the inconvenience, but at the moment the site is under maintenance.</p>

<?php if ($status) : ?>
    <p><b>Status: <?php echo $status ?></b></p>
<?php endif; ?>

<p><img src="/dummy/uc.jpg" align="center" width="600"></p>
<p>Soon we will be back online!</p>
</body>
</html>