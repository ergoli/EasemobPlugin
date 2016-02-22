var exec = require('cordova/exec');

exports.init = function(arg0, success, error) {
    exec(success, error, "EasemobPlugin", "init", [arg0]);
};

exports.login = function(userName, password, success, error) {
    exec(success, error, "EasemobPlugin", "login", [userName, password]);
};

exports.chat = function(arg0, success, error) {
    exec(success, error, "EasemobPlugin", "chat", [arg0]);
};