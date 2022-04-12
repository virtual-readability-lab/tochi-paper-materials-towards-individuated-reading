const express = require('express')
const path = require('path')
const bodyParser = require('body-parser')
const http = require('http')
const https = require('https')
const app = express()
const server = http.createServer(app)

const fs = require('fs')
try {
  // in production you can link to your certs here for HTTPS
  //const privateKey  = fs.readFileSync('server.key', 'utf8')
  //const certificate = fs.readFileSync('server.cert', 'utf8')
  const credentials = {key: privateKey, cert: certificate}
  var httpsServer = https.createServer(credentials, app)
  httpsServer.listen(8443, function(){
    console.log('https listening on *:8443');
  });
} catch (error) {
  console.log('ERROR did not launch https on *:8443');
}
server.listen(3000, function(){
  console.log('http listening on *:3000');
});

const sqlite3 = require('sqlite3').verbose()

let db = new sqlite3.Database(__dirname + '/db/readability.db', sqlite3.OPEN_READWRITE, (err) => {
  if (err) {
    console.error(err.message)
  }
  console.log('Connected to database.') 

  db.serialize(function () {
    db.run("CREATE TABLE IF NOT EXISTS users (id_user INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, user_type TEXT, timestamp INTEGER DEFAULT CURRENT_TIMESTAMP )")
    db.run("CREATE TABLE IF NOT EXISTS choices (id_choice INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, id_user INTEGER, font_a TEXT, font_b TEXT, winning_font TEXT, matchup INTEGER, bracket TEXT, dwell_time_a REAL, dwell_time_b REAL, views_a INTEGER, views_b INTEGER, width INTEGER, height INTEGER, device TEXT, study_step TEXT, timestamp INTEGER )"),
    db.run("CREATE TABLE IF NOT EXISTS xy (id_xy INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, id_user INTEGER, block TEXT, round INTEGER, iteration INTEGER, x INTEGER, y INTEGER, reading_preference INTEGER, reading_speed INTEGER, study_step TEXT, timestamp INTEGER)"),
    db.run("CREATE TABLE IF NOT EXISTS xyword (id_xyword INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, id_user INTEGER, font TEXT, block TEXT, mouse_event TEXT, id_passage INTEGER, id_word INTEGER, word TEXT, x INTEGER, y INTEGER, study_step TEXT, timestamp INTEGER)"),
    db.run("CREATE TABLE IF NOT EXISTS speed (id_speed INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, id_user INTEGER, font TEXT, iteration INTEGER, id_passage INTEGER, passage INTEGER, words INTEGER, chars INTEGER, sentences INTEGER, wpm INTEGER, seconds REAL, study_step TEXT, timestamp INTEGER)"),
    db.run("CREATE TABLE IF NOT EXISTS comprehension (id_comprehension INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, id_user INTEGER, font TEXT, id_passage, question TEXT, answer TEXT, correct INTEGER, study_step TEXT, timestamp INTEGER)"),
    db.run("CREATE TABLE IF NOT EXISTS miniq (id_miniq INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, id_user INTEGER, font TEXT, id_passage INTEGER, question TEXT, answer TEXT, answer_num INTEGER, study_step TEXT, timestamp INTEGER)"),
    db.run("CREATE TABLE IF NOT EXISTS fontfamiliarity (id_fontfamiliarity INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, id_user INTEGER, font TEXT, answer TEXT, answer_num INTEGER, timestamp INTEGER)"),
    db.run("CREATE TABLE IF NOT EXISTS fontchamps (id_fontchamp INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, id_user INTEGER, font TEXT, study_step TEXT, timestamp INTEGER)"),
    db.run("CREATE TABLE IF NOT EXISTS passages (id_passage INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, source TEXT, pdf_corpus1 TEXT,pdf_corpus2 TEXT, passage1 TEXT, passage2 TEXT, passage3 TEXT,passage4 TEXT,question1 TEXT,choice1_q1 TEXT,choice2_q1 TEXT,choice3_q1 TEXT,answer_q1 TEXT,question2 TEXT,choice1_q2 TEXT,choice2_q2 TEXT,choice3_q2 TEXT,answer_q2 TEXT,question3 TEXT,choice1_q3 TEXT, choice2_q3 TEXT, choice3_q3 TEXT, answer_q3 TEXT)"),
    db.run("CREATE TABLE IF NOT EXISTS normalization (id_normalization INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, id_user INTEGER, choice TEXT, font TEXT, normalization TEXT, dwell_time REAL, winner_views INTEGER, total_views INTEGER, toggles INTEGER, passages INTEGER, timestamp INTEGER)")
  })
});

app.use(express.static('public'))
app.use(express.urlencoded())
app.use(express.json())
const cors = require('cors')
var corsOptions = {
  origin: '*',
  optionsSuccessStatus: 200 // some legacy browsers (IE11, various SmartTVs) choke on 204 
}
app.use(cors(corsOptions));

//DB Code
var insertUserId = function (user_type, timestamp, callback) {
  db.run('INSERT INTO users (id_user, user_type, timestamp) VALUES (NULL,?,?)', [user_type, timestamp], function (err) {
    if (err) {
      console.log('ERROR - INSERT INTO users: ' + err.message)
    }
    console.log('NewRow(user),inserted, id=' + this.lastID + ',user_type=' + user_type)
    callback(this.lastID)
  })
}

// GET
app.get('/', function(req, res) {
  res.sendFile(__dirname + '/index.html');
});

app.get('/api/v1/newuser', function(req, res) {
  //console.log('newuser timestamp: ' + req.query.timestamp)
  insertUserId(req.query.user_type, req.query.timestamp, function(id_user){
    res.send(String(id_user))
  });
});

/////// POST
app.post('/api/v1/newchoice', (req, res) => {
  db.run('INSERT INTO choices (id_choice, id_user, font_a, font_b, winning_font, matchup, bracket, dwell_time_a, dwell_time_b, views_a, views_b, width, height, device, study_step, timestamp) VALUES (NULL,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)', 
          [req.body.id_user, req.body.font_a, req.body.font_b, req.body.winning_font, req.body.matchup, req.body.bracket, req.body.dwell_time_a, req.body.dwell_time_b, req.body.views_a, req.body.views_b, req.body.width, req.body.height, req.body.device, req.body.study_step, req.body.timestamp], function (err) {
    if (err) {
      console.log('ERROR - INSERT INTO choices: ' + err.message)
    }
  })

  return res.status(201).send({
    success: 'true',
    message: 'success'
  })
});

app.post('/api/v1/trackxy', (req, res) => {
  db.run('INSERT INTO xy (id_xy, id_user, block, round, iteration, x, y, reading_preference, reading_speed, study_step, timestamp) VALUES (NULL,?,?,?,?,?,?,?,?,?,?)', 
          [req.body.id_user, req.body.block, req.body.round, req.body.iteration, req.body.x, req.body.y, req.body.reading_preference, req.body.reading_speed, req.body.study_step, req.body.timestamp], function (err) {
    if (err) {
      console.log('ERROR - INSERT INTO xy: ' + err.message)
    }
  })

  return res.status(201).send({
    success: 'true',
    message: 'success'
  })
});

app.post('/api/v1/speed', (req, res) => {
  db.run('INSERT INTO speed (id_speed, id_user, font, iteration, id_passage, passage, words, chars, sentences, wpm, seconds, study_step, timestamp) VALUES (NULL,?,?,?,?,?,?,?,?,?,?,?,?)', 
          [req.body.id_user, req.body.font, req.body.iteration, req.body.id_passage, req.body.passage, req.body.words, req.body.chars, req.body.sentences, req.body.wpm, req.body.seconds, req.body.study_step, req.body.timestamp], function (err) {
    if (err) {
      console.log('ERROR - INSERT INTO speed: ' + err.message)
    }
  })

  return res.status(201).send({
    success: 'true',
    message: 'success'
  })
});

app.post('/api/v1/comprehension', (req, res) => {
  db.run('INSERT INTO comprehension (id_comprehension, id_user, font, id_passage, question, answer, correct, study_step, timestamp) VALUES (NULL,?,?,?,?,?,?,?,?)', 
          [req.body.id_user, req.body.font, req.body.id_passage, req.body.question, req.body.answer, req.body.correct, req.body.study_step, req.body.timestamp], function (err) {
    if (err) {
      console.log('ERROR - INSERT INTO comprehension: ' + err.message)
    }
  })

  return res.status(201).send({
    success: 'true',
    message: 'success'
  })
});

app.post('/api/v1/miniq', (req, res) => {
  db.run('INSERT INTO miniq (id_miniq, id_user, font, id_passage, question, answer, answer_num, study_step, timestamp) VALUES (NULL,?,?,?,?,?,?,?,?)', 
          [req.body.id_user, req.body.font, req.body.id_passage, req.body.question, req.body.answer, req.body.answer_num, req.body.study_step, req.body.timestamp], function (err) {
    if (err) {
      console.log('ERROR - INSERT INTO miniq: ' + err.message)
    }
  })

  return res.status(201).send({
    success: 'true',
    message: 'success'
  })
});

app.post('/api/v1/xyword', (req, res) => {
  db.run('INSERT INTO xyword (id_xyword, id_user, font, block, mouse_event, id_passage, id_word, word, x, y, study_step, timestamp) VALUES (NULL,?,?,?,?,?,?,?,?,?,?,?)', 
          [req.body.id_user, req.body.font, req.body.block, req.body.mouse_event, req.body.id_passage, req.body.id_word, req.body.word, req.body.x, req.body.y, req.body.study_step, req.body.timestamp], function (err) {
    if (err) {
      console.log('ERROR - INSERT INTO xyword: ' + err.message)
    }
  })

  return res.status(201).send({
    success: 'true',
    message: 'success'
  })
});

app.post('/api/v1/fontfamiliarity', (req, res) => {
  db.run('INSERT INTO fontfamiliarity (id_fontfamiliarity, id_user, font, answer, answer_num, timestamp) VALUES (NULL,?,?,?,?,?)', 
          [req.body.id_user, req.body.font, req.body.answer, req.body.answer_num, req.body.timestamp], function (err) {
    if (err) {
      console.log('ERROR - INSERT INTO fontfamiliarity: ' + err.message)
    }
  })

  return res.status(201).send({
    success: 'true',
    message: 'success'
  })
});

app.post('/api/v1/fontchamp', (req, res) => {
  db.run('INSERT INTO fontchamps (id_fontchamp,id_user,font,study_step,timestamp) VALUES (NULL,?,?,?,?)', 
          [req.body.id_user, req.body.font, req.body.study_step, req.body.timestamp], function (err) {
    if (err) {
      console.log('ERROR - INSERT INTO fontchamps: ' + err.message)
    }
  })

  return res.status(201).send({
    success: 'true',
    message: 'success'
  })
});

app.post('/api/v1/normalization', (req, res) => {
  db.run('INSERT INTO normalization (id_normalization, id_user, choice, font, normalization, dwell_time, winner_views, total_views, toggles, passages, timestamp) VALUES (NULL,?,?,?,?,?,?,?,?,?,?)', 
          [req.body.id_user, req.body.choice, req.body.font, req.body.normalization, req.body.dwell_time, req.body.winner_views, req.body.total_views, req.body.toggles, req.body.passages, req.body.timestamp], function (err) {
    if (err) {
      console.log('ERROR - INSERT INTO normalization: ' + err.message)
    }
  })

  return res.status(201).send({
    success: 'true',
    message: 'success'
  })
});

app.post('/api/v1/testpost', (req, res) => {
  console.log('req: ' + req.body.data)
  return res.status(201).send({
    success: 'true',
    message: 'success'
  })
});
