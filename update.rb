require 'dota'

def get_list
  api = Dota.api
  heroes = api.heroes
  f1 = File.open('hero_list','w') 
  heroes.each {|hero| f1.puts(hero.instance_variable_get('@internal_name'))}
  f1.close
  items = api.items
  f2 = File.open('item_list','w')
  items.each {|item| f2.puts(item.instance_variable_get('@internal_name'))} 
  f2.close
  abilities = api.abilities
  f3 = File.open('ability_list','w') 
  abilities.each {|ability| f3.puts(ability.instance_variable_get('@internal_name'))}
  f3.close
end

def wget_hero(type)
  path = File.expand_path(File.dirname(__FILE__))
  hero_base = "http://cdn.dota2.com/apps/dota2/images/heroes/"
  directory_name = "heroes_" + type.to_s
  Dir.mkdir(directory_name) unless File.exists?(directory_name)
  Dir.chdir(File.expand_path("./" + directory_name, File.dirname(__FILE__)))
  File.open(path + '/hero_list').each do |line|
    fname = "#{line.strip}_#{type}.#{type == :vert ? 'jpg' : 'png'}"
    %x(wget -q #{hero_base + fname}) unless File.exists?(fname)
  end
  Dir.chdir(path)
end

def wget_item(type)
  path = File.expand_path(File.dirname(__FILE__))
  item_base = "http://cdn.dota2.com/apps/dota2/images/items/"
  directory_name = "items_" + type.to_s
  Dir.mkdir(directory_name) unless File.exists?(directory_name)
  Dir.chdir(File.expand_path("./" + directory_name, File.dirname(__FILE__)))
  File.open(path + '/item_list').each do |line|
    if line =~ /\Arecipe/
      fname = "#{line.strip.sub('recipe_','')}_#{type}.png"
    else
      fname = "#{line.strip}_#{type}.png"
    end

    %x(wget -q #{item_base + fname}) unless File.exists?(fname)
  end
  Dir.chdir(path)
end

def wget_ability(type)
  path = File.expand_path(File.dirname(__FILE__))
  ability_base = "http://cdn.dota2.com/apps/dota2/images/abilities/"
  directory_name = "abilities_" + type.to_s
  Dir.mkdir(directory_name) unless File.exists?(directory_name)
  Dir.chdir(File.expand_path("./" + directory_name, File.dirname(__FILE__)))
  File.open(path + '/ability_list').each do |line|
    fname = "#{line.strip}_#{type}.png"
    %x(wget -q #{ability_base + fname}) unless File.exists?(fname)
  end
  Dir.chdir(path)
end

def index_update
  require 'erb'
  path = File.expand_path(File.dirname(__FILE__))
  reg = path + "/"
  hero_path = Dir[File.expand_path("./heroes_sb/*",File.dirname(__FILE__))].map {|x| x.sub(reg,'')}
  item_path = Dir[File.expand_path("./items_eg/*",File.dirname(__FILE__))].map {|x| x.sub(reg,'')}
  ability_path = Dir[File.expand_path("./abilities_sm/*",File.dirname(__FILE__))].map {|x| x.sub(reg,'')}
  renderer = ERB.new(File.read('index.html.erb'))
  File.open("index.html",'w') { |f| f.write(renderer.result(binding)) }
end

def wget
  wget_hero(:vert)
  wget_hero(:lg)
  wget_hero(:full)
  wget_hero(:sb)
  wget_item(:lg)
  wget_item(:eg)
  wget_ability(:lg)
  wget_ability(:md)
  wget_ability(:sm)
  wget_ability(:hp1)
  wget_ability(:hp2)
end

def zip_images
  dir = Dir['*'].select{|i| i =~ /\A(abilities|heroes|items)/ }
  dir.each do |d|
    %x(zip -r9X #{d + '_latest.zip'} #{d}) 
    fname = d + '_latest.zip'
    %x(mv #{fname} #{"file/" + fname.gsub('_', '-')}) 
  end 
end

def update
  puts "## Get list"
  get_list
  puts "## Wget"
  wget
  message = `git status`
  puts "## Updating"
  if message.include?("Changes")
    zip_images
    index_update
    `git add .`
    `git commit -m "Build at #{Time.now}"`
  end
  puts "## Success"
end

update
