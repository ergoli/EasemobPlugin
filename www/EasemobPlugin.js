var exec = require('cordova/exec');

exports.init = function(arg0, success, error) {
    exec(success, error, "EasemobPlugin", "init", [arg0]);
};

exports.login = function(userName, password, success, error) {
    exec(success, error, "EasemobPlugin", "login", [userName, password]);
};

exports.chat = function(userID, usersList, success, error) {
    exec(success, error, "EasemobPlugin", "chat", [userID, usersList]);
};

exports.chatRoom = function(roomID, usersList, success, error) {
    exec(success, error, "EasemobPlugin", "chatRoom", [roomID, usersList]);
};



var EasemobPlugin = function(){
};

EasemobPlugin.prototype.receiveEasemobMessageInAndroidCallback = function(data){
	try{
		var bToObj  = JSON.parse(data);
		cordova.fireDocumentEvent('Easemob.receiveEasemobMessage',bToObj);
	}
	catch(exception){       
		console.log(exception);
	}
}

if(!window.plugins){
	window.plugins = {};
}

if(!window.plugins.easemobPlugin){
	window.plugins.easemobPlugin = new EasemobPlugin();
}  

module.exports = new EasemobPlugin(); 