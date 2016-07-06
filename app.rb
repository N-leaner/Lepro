#encoding: utf-8
require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'

def init_db
	@db = SQLite3::Database.new 'lepra.db'
	@db.results_as_hash = true
end	

before do
	init_db
end

configure do
	init_db
	@db.execute 'CREATE TABLE IF NOT EXISTS Posts 
	(
	id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, 
	created_date DATETIME, 
	content TEXT,
	autor VARCHAR
	)'

	@db.execute 'CREATE TABLE IF NOT EXISTS Comments 
	(
	id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, 
	post_id INTEGER,
	created_date DATETIME, 
	comment TEXT
	)'
end	

get '/' do
	#выбираем посты из бд:
	@result = @db.execute 'select * from Posts order by id desc'
	@c_comn = @db.execute 'select post_id, COUNT(*) as count from Comments group by post_id'
	erb :index
end

get '/' do
  erb :new
end

get '/new' do
  erb :new
end

post '/new' do
  content = params[:content].strip
  @autor = params[:autor].strip.capitalize

  if @autor.length == 0
  	@error = "Please, type the damn autor name!"  	
  	return erb :new
  end

  if content.length == 0
  	@error = "Please, type the damn post text!"  	
  	return erb :new
  end	

  @db.execute "insert into Posts 
  (
  content, 
  created_date, 
  autor
  ) values (
  ?,
  datetime('now','localtime'),
  ?
  )",[content,@autor]
  #перенаправление на главную
  redirect to '/'
end

get '/details/:post_id' do
	#получаем переменную из url-a
	post_id = params[:post_id]

	#получаем пост
	result = @db.execute 'select * from Posts where id = ?',[post_id]
	if result.empty?
		redirect to '/'
	else
		@row = result[0]
		@comments = @db.execute 'select * from Comments where post_id = ? order by id',[post_id]
		erb :details
	end	
end

post '/details/:post_id' do
	comment = params[:comment].strip
	post_id = params[:post_id]

	result = @db.execute 'select * from Posts where id = ?',[post_id]
	@row = result[0]
	@comments = @db.execute 'select * from Comments where post_id = ? order by id',[post_id]

	if comment.length == 0		
		@error = "Please, puts some comment"				
		erb :details
	else
		@db.execute "insert into Comments 
		(
			post_id, 
			created_date, 
			comment
		) 
		values 
		(
			?,
			datetime('now','localtime'),
			?
		)",[post_id, comment]

		redirect to '/details/'+post_id
	end	
end