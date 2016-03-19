require 'sinatra'
require 'json'

class TodoApp < Sinatra::Base
  def initialize(repo)
    super
    @repo = repo
  end

  configure :development do
    require 'sinatra/reloader'
    register Sinatra::Reloader
  end

  before do
    headers "access-control-allow-origin" => "*"
    if env.has_key? "HTTP_ACCESS_CONTROL_REQUEST_HEADERS"
      headers "access-control-allow-headers" => env["HTTP_ACCESS_CONTROL_REQUEST_HEADERS"]
    end
  end

  def json_body
    JSON.parse(request.env["rack.input"].read, :symbolize_names=> true)
  end

  def todos_url
    uri( "/todos" )
  end

  def todo_url(todo)
    uri( "/todos/#{todo["uid"] || todo[:uid]}" )
  end

  def todo_repr(todo)
    todo.merge({
      "href" => todo_url(todo),
      "url" => todo_url(todo)
    })
  end

  get '/' do
    redirect todos_url
  end

  options '/todos' do
    headers "access-control-allow-methods" => "GET,HEAD,POST,DELETE,OPTIONS,PUT"
  end

  get '/todos' do
    @repo.all_todos.map{|t|todo_repr(t)}.to_json
    # content_type :json
  end

  post "/todos" do
    new_todo = json_body
    stored_todo = @repo.add_todo(new_todo)

    headers["Location"] = todo_url(stored_todo)
    status 201
    # content_type :json
    todo_repr(stored_todo).to_json
  end

  delete "/todos" do
    @repo.clear!
    status 204
  end

  def lookup_todo_or_404
    todo = @repo[params[:todo_uid]]
    halt 404 if todo.nil?
    todo
  end

  options '/todos/:todo_uid' do
    headers "access-control-allow-methods" => "GET,PATCH,HEAD,DELETE,OPTIONS"
  end

  get "/todos/:todo_uid" do
    todo_repr(lookup_todo_or_404).to_json
  end

  delete "/todos/:todo_uid" do
    @repo.delete(params[:todo_uid])
    status 204
  end

  patch "/todos/:todo_uid" do
    todo = lookup_todo_or_404
    todo.merge!( json_body )
    @repo[todo.fetch(:uid)] = todo
    todo_repr(todo).to_json
  end

  get "/favicon.ico" do
  end
end
