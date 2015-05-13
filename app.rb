require 'mechanize'
require 'open-uri'
require 'json'
require 'yaml'
require 'colorize'
require_relative './helpers'

$:.unshift File.dirname($0)

class String
  def to_path
    "#{'/' if self[0]=='\\'}#{self.split('\\').join('/')}"
  end 
end

def get_status(url)
  JSON.parse(open(url).read)['status']
end

conf = YAML.load_file('config.yml')
input = conf['directories'].map do |d|
  path = "#{d}\\*.epub".to_path
  Dir.glob(path).to_a
end.flatten

mechanize = Mechanize.new do |a|
  a.ssl_version, a.verify_mode = 'SSLv3', OpenSSL::SSL::VERIFY_NONE
end

input.each do |file|
  basename = File.basename(file)
  
  page = mechanize.get('http://www.epub2mobi.com')
  puts "> #{basename}".colorize(:green)

  result = Helpers.waiting_op("Отправка на сервер") do
    page.form_with(:method => /POST/) do |f|
       f.file_uploads.first.file_name = file
    end.click_button
  end

  code = result.uri.to_s.split('/').last
  url = "http://www.epub2mobi.com/result/#{code}.json"

  Helpers.wait_while("Инициализация") do
    get_status(url) == "INITIAL"
  end

  Helpers.wait_while("В очереди") do
    get_status(url) == "QUEUE"
  end

  Helpers.wait_while("Обработка файла") do
    get_status(url) == "PROCESSING"
  end

  out_fn = File.join(File.dirname(file), File.basename(file, '.*') + '.mobi')

  Helpers.waiting_op("Загрузка файла с сервера") do
    open(out_fn, 'wb') do |f|
      f << open("http://www.epub2mobi.com/download/#{code}").read
    end
  end

  puts 'Файл был успешно сконвертирован!'
  File.delete(file) # удаление исходного файла
  puts "\n"
end