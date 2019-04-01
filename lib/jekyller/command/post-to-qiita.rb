require 'yaml'

root_url = ARGV.shift
filename = ARGV.shift

post_path = "/#{filename.split(/-/, 4).join('/').gsub(/\.md/, '')}/"

post_url = "#{root_url}#{post_path}"

yaml_flag = false

yaml_text = ''

STDIN.each do |line|
  if /^---$/ =~ line
    if yaml_flag
      config = YAML.load(yaml_text)
      title = config['title']
      puts title
      puts
      puts "※ この記事は[江の島エンジニアBlog](#{root_url}/)の「[#{title}](#{post_url})」の転載です。"
      puts
      puts config['description']
    end
    yaml_flag ^= true
  elsif yaml_flag
    yaml_text << line
  elsif /\{% *highlight ([^ %]+)*\s*%\}/ =~ line
    puts "```#{Regexp.last_match(1)}"
  elsif /\{% *endhighlight *%\}/ =~ line
    puts "```"
  else
    print line
  end
end
