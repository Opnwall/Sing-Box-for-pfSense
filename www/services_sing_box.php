<?php
require_once("guiconfig.inc");

$pgtitle = [gettext('Services'), gettext('Sing-box')];
include("head.inc");

// 配置文件路径
$config_file = "/usr/local/etc/sing-box/config.json";
$log_file = "/var/log/sing-box.log";

// 初始化消息变量
$message = "";

display_top_tabs($tab_array);

// 服务控制函数
function handleServiceAction($action)
{
    $allowedActions = ['start', 'stop', 'restart'];
    if (!in_array($action, $allowedActions)) {
        return "无效的操作！";
    }

    // 清空日志文件（仅在启动或重启时）
    if ($action === 'start' || $action === 'restart') {
        file_put_contents("/var/log/sing-box.log", ""); // 清空日志文件
    }

    // 执行服务操作
    exec("service sing-box " . escapeshellarg($action), $output, $return_var);
    $messages = [
        'start' => ["Sing-Box服务启动成功！", "Sing-Box服务启动失败！"],
        'stop' => ["Sing-Box服务已停止！", "Sing-Box服务停止失败！"],
        'restart' => ["Sing-Box服务重启成功！", "Sing-Box服务重启失败！"]
    ];
    return $return_var === 0 ? $messages[$action][0] : $messages[$action][1];
}

// 配置保存函数
function saveConfig($file, $content)
{
    if (!is_writable($file)) {
        return "配置保存失败，请确保文件可写。";
    }

    if (file_put_contents($file, $content) !== false) {
        return "配置保存成功！";
    }

    return "配置保存失败！";
}

// 表单提交处理
if ($_POST) {
    $action = $_POST['action'] ?? '';
    if ($action === 'save_config') {
        $config_content = $_POST['config_content'] ?? '';
        $message = saveConfig($config_file, $config_content);
    } else {
        $message = handleServiceAction($action);
    }
}


// 加载配置文件内容
$config_content = file_exists($config_file) ? htmlspecialchars(file_get_contents($config_file)) : "配置文件未找到！";
?>

<div>
    <?php if (!empty($message)): ?>
    <div class="alert alert-info">
        <?= htmlspecialchars($message); ?>
    </div>
    <?php endif; ?>
</div>
<!-- 服务状态 -->
<div class="panel panel-default">
    <div class="panel-heading">
        <h2 class="panel-title">服务状态</h2>
    </div>
    <div class="panel-body">
        <div id="sing-box-status" class="alert alert-secondary">
            <i class="fa fa-circle-notch fa-spin"></i> 检查中...
        </div>
    </div>
</div>
<!-- 服务控制 -->
<div class="panel panel-default">
    <div class="panel-heading">
        <h2 class="panel-title">服务控制</h2>
    </div>
    <div class="form-group">
        <form method="post" class="form-inline">
            <button type="submit" name="action" value="start" class="btn btn-success">
                <i class="fa fa-play"></i> 启动
            </button>
            <button type="submit" name="action" value="stop" class="btn btn-danger">
                <i class="fa fa-stop"></i> 停止
            </button>
            <button type="submit" name="action" value="restart" class="btn btn-warning">
                <i class="fa fa-sync"></i> 重启
            </button>
        </form>
    </div>
</div>
<!-- 配置管理 -->
<div class="panel panel-default">
    <div class="panel-heading">
        <h2 class="panel-title">配置管理</h2>
    </div>
    <div class="form-group">
        <form method="post">
            <textarea name="config_content" rows="10" class="form-control"><?= $config_content; ?></textarea>
            <br>
            <button type="submit" name="action" value="save_config" class="btn btn-primary">
                <i class="fa fa-save"></i> 保存配置
            </button>
        </form>
    </div>
</div>
<!-- 日志查看 -->
<div class="panel panel-default">
    <div class="panel-heading">
        <h2 class="panel-title">日志查看</h2>
    </div>
    <div class="form-group">
        <textarea id="log-viewer" rows="10" class="form-control" readonly></textarea>
    </div>
</div>

<script>
// 检查服务状态
function checkSingBoxStatus() {
    fetch('/status_sing_box.php')
        .then(response => response.json())
        .then(data => {
            const statusElement = document.getElementById('sing-box-status');
            if (data.status === "running") {
                statusElement.innerHTML = '<i class="fa fa-check-circle text-success"></i> Sing-Box正在运行';
                statusElement.className = "alert alert-success";
            } else {
                statusElement.innerHTML = '<i class="fa fa-times-circle text-danger"></i> Sing-Box已停止';
                statusElement.className = "alert alert-danger";
            }
        });
}

// 实时刷新日志
function refreshLogs() {
    fetch('/status_sing_box_logs.php')
        .then(response => response.text())
        .then(logContent => {
            const logViewer = document.getElementById('log-viewer');
            logViewer.value = logContent;
            logViewer.scrollTop = logViewer.scrollHeight;
        })
        .catch(error => {
            console.error("日志刷新失败:", error.message);
            const logViewer = document.getElementById('log-viewer');
            logViewer.value += "\n[错误] 无法加载日志，请检查网络或服务器状态。\n";
            logViewer.scrollTop = logViewer.scrollHeight;
        });
}

// 初始化
document.addEventListener('DOMContentLoaded', () => {
    checkSingBoxStatus();
    refreshLogs();
    setInterval(checkSingBoxStatus, 3000);
    setInterval(refreshLogs, 2000);
});
</script>

<?php include("foot.inc"); ?>
