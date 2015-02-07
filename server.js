var express = require('express');
var mongo = require('mongojs');
var mongoUri = "mongodb://";
var db = mongo.connect(mongoUri);
var app = express();

app.set('port', (process.env.PORT || 5000));
app.use(express.static(__dirname + '/public'));




function onlineGame(username,startTime) {
    this.username = username;
    this.gameStart = startTime;
    this.tickCount = 0;
}
var gameList = [];


setInterval(function() {
	var d = new Date();
	var destroyList = [];
	console.log(gameList)
	for(var x = 0; x < gameList.length; x++){
		if(gameList[x].gameStart +  gameList[x].tickCount + 10000 < d.getTime()){
			destroyList.push(gameList[x].username);
		}
	}
	clearGameList(destroyList);
}, 1000);

function clearGameList(arr){
	for(var x = 0; x < arr.length; x++){
		gameList.deleteGame(arr[x]);
	}
}


app.post("/prostats/note/public/:username/:targetUsername", function(request,response){
	db.collection("users").find({username:request.param("username")},function(err, obj){
		if(err){
			response.write("0, An error occured on updating status.");
			response.end();
		}else{
			if(obj.length == 0){
				response.write("0, You are not registered to the system.");
				response.end();
			}else{
				if(request.param("targetUsername")){
					if(gameList.gameExist(request.param("username"))){
						response.write("1, Done.");
						response.end();
					}else{
						response.write("0, You are not in a game.");
						response.end();
					}
				}else{
					response.write("0, Bad arguments in update part.");
					response.end();
				}
			}
		}
	});
});

app.post("/prostats/note/private/:username/:targetUsername", function(request,response){
	db.collection("users").find({username:request.param("username")},function(err, obj){
		if(err){
			response.write("0, An error occured on updating status.");
			response.end();
		}else{
			if(obj.length == 0){
				response.write("0, You are not registered to the system.");
				response.end();
			}else{
				if(request.param("targetUsername")){
					if(gameList.gameExist(request.param("username"))){
						response.write("1, Done.");
						response.end();
					}else{
						response.write("0, You are not in a game.");
						response.end();
					}
				}else{
					response.write("0, Bad arguments in update part.");
					response.end();
				}
			}
		}
	});
});

app.post("/prostats/note/:username/:targetUsername", function(request,response){
	db.collection("users").find({username:request.param("username")},function(err, obj){
		if(err){
			response.write("0, An error occured on updating status.");
			response.end();
		}else{
			if(obj.length == 0){
				response.write("0, You are not registered to the system.");
				response.end();
			}else{
				if(request.param("targetUsername")){
					if(gameList.gameExist(request.param("username"))){
						response.write("1, Done.");
						response.end();
					}else{
						response.write("0, You are not in a game.");
						response.end();
					}
				}else{
					response.write("0, Bad arguments in update part.");
					response.end();
				}
			}
		}
	});
});

app.post("/prostats/scriptReporter/:username/:targetUsername", function(request,response){
	db.collection("users").find({username:request.param("username")},function(err, obj){
		if(err){
			response.write("0, An error occured on updating status.");
			response.end();
		}else{
			if(obj.length == 0){
				response.write("0, You are not registered to the system.");
				response.end();
			}else{
				if(request.param("targetUsername")){
					if(gameList.gameExist(request.param("username"))){
						response.write("1, Done.");
						response.end();
					}else{
						response.write("0, You are not in a game.");
						response.end();
					}
				}else{
					response.write("0, Bad arguments in update part.");
					response.end();
				}
			}
		}
	});
});

app.post('/prostats/stat/:username/:tick', function(request, response) {
	db.collection("stats").find({tick:{ $gt : parseInt(request.param("tick"))-3, $lt : parseInt(request.param("tick"))+3 },username:request.param("username")},function(err,obj){
		if(err){
			response.write("0,An error occured getting stats.");
			response.end();
		}else{
			var avg = {
				kill:0,
				death:0,
				assist:0,
				minion:0
			}
			for(var x = 0; x < obj.length;x++){
				avg.kill += obj[x].kill;
				avg.death += obj[x].death;
				avg.assist += obj[x].assist;
				avg.minion += obj[x].minion;
			}
			console.log(avg)
			for(var x in avg){
				avg[x] = Math.round(parseInt(avg[x])/obj.length)? Math.round(parseInt(avg[x])/obj.length) : 0;
			}
			response.write("1,"+avg.kill+","+avg.death+","+avg.assist+","+avg.minion);
			response.end();
		}
	});
});

app.post('/prostats/init/:username', function(request, response) {
	db.collection("users").find({username:request.param("username")},function(err, obj){
		if(err){
			response.write("0, An error occured while initializing.");
			response.end();
		}else{
			if(obj.length == 0){
				createUser(request.param("username"),response)
			}else{
				response.write("1,Username authenticated Good luck!");
				response.end();	
			}
		}
	});
});

app.use("/images", express.static(__dirname + '/images'));

app.post('/prostats/tick/:username/:kill/:death/:assist/:minion/:tick/:gameId', function(request, response) {
	db.collection("users").find({username:request.param("username")},function(err, obj){
		if(err){
			response.write("0, An error occured on updating status.");
			response.end();
		}else{
			if(obj.length == 0){
				response.write("0, You are not registered to the system.");
				response.end();
			}else{
				if(request.param("username") && request.param("kill") && request.param("death") && request.param("assist") && request.param("minion") && request.param("tick") && request.param("gameId")){
					if(gameList.gameExist(request.param("username"))){
						tick(request.param("username"),{username:request.param("username"),kill:request.param("kill"),death:request.param("death"),assist:request.param("assist"),minion:request.param("minion"),tick:request.param("tick"),gameId:request.param("gameId")},response);
					}else{
						response.write("0, You are not in a game.");
						response.end();
					}
				}else{
					response.write("0, Bad arguments in update part 1.");
					response.end();
				}
			}
		}
	});
});


app.post('/prostats/start/:username', function(request, response) {
	db.collection("users").find({username:request.param("username")},function(err, obj){
		if(!err){
			if(obj.length == 1){
				if(!gameList.gameExist(request.param("username"))){
					var d = new Date();
					var game = new onlineGame(request.param("username"),d.getTime());
					gameList.push(game);
					response.write("1, Game recording started succesfully.");
					response.end();
				}else{
					response.write("1, You are already in a game.");
					response.end();
				}
			}else{
				response.write("0, You are not registered to the system.");
				response.end();
			}
		}else{
			response.write("0, An error occured while starting game.");
			response.end();
		}
	});
});

app.listen(app.get('port'), function() {
  console.log("Node app is running at localhost:" + app.get('port'));
});

function createUser(username,response){
	db.collection("users").insert({username:username,gameCount:1}, function(err,obj){
		if(!err){
			response.write("2,Welcome to Prostats! Your account created succesfully. Good luck!");
			response.end();
		}else{
			response.write("0,An error occured. Your account can't be created.");
			response.end();
		}
	});
}

function tick(username,params,response){
	
	for(var x in params){
		if(!params[x].isNumber()){
			if(x != "username"){
				response.write("0, Bad arguments in update.");
				response.end();
				return false;
			}
		}else{
			params[x] = parseInt(params[x]);
		}
	}
	var game = gameList.gameFindByUsername(username)
	if(game){
		db.collection("stats").insert(params);
		var d = new Date();
		game.tickCount = d.getTime();
		db.collection("stats").find({tick:{ $gt : params.tick-5, $lt : params.tick+5 },username:username,gameId:{$ne:params.gameId}},function(err,obj){
			if(err){
				response.write("0,An error occured getting stats.");
				response.end();
			}else{
				var avg = {
					kill:0,
					death:0,
					assist:0,
					minion:0
				}
				for(var x = 0; x < obj.length;x++){
					avg.kill += obj[x].kill;
					avg.death += obj[x].death;
					avg.assist += obj[x].assist;
					avg.minion += obj[x].minion;
				}
				console.log(obj)
				for(var x in avg){
					avg[x] = Math.round(parseInt(avg[x])/obj.length)? Math.round(parseInt(avg[x])/obj.length) : 0;
				}
				response.write("1,"+avg.kill+","+avg.death+","+avg.assist+","+avg.minion);
				response.end();
			}
		});
	}else{
		response.write("0, Game not found.");
		response.end();
	}

}

function gameEnd(username){

}

Array.prototype.gameExist = function(username){
	for(var x = 0; x < this.length; x++){
		if(this[x].username == username){
			return true
		}
	}
	return false;
}

Array.prototype.gameFindByUsername = function(username){
	for(var x = 0; x < this.length; x++){
		if(this[x].username == username){
			return this[x];
		}
	}
	return false;
}


Array.prototype.deleteGame = function(username){
	var index = -1
	for(var x = 0; x < this.length; x++){
		if(this[x].username == username){
			index = x;
		}
	}
	if(index != -1){
		this.splice(index, 1);
	}
}

String.prototype.isNumber = function(){
	return /^\d+$/.test(this);
}
