#!/usr/bin/env ruby
require "date"
require "erb"
require "optparse"

command = ARGV.shift.to_sym

posts_dir = "_posts"
drafts_dir = "_drafts"
template_dir = "_template"

output_type = :post
create_force = false
post_date = Date.today
title = nil
tags = []
keywords = nil
description = nil
template_name = "default"

op = OptionParser.new

op.on("-f") { create_force = true }
op.on("-d NUM", Integer) { |i| post_date += i }
op.on("--title TITLE", String) { |s| title = s }
op.on("--tags TAGS", String) { |s| tags = s.split(/,/) }
op.on("--keywords KEYWORDS", String) { |s| keywords = s.split(/,/) }
op.on("--description DESCRIPTION", String) { |s| description = s }
op.on("--template NAME", String) { |s| template_name = s }

op.parse!(ARGV)

names = ARGV

keywords ||= tags

post_time = "#{post_date.strftime("%Y-%m-%d")} #{Time.now.strftime("%H:%M:%S")}J"

template_file = "#{template_dir}/#{template_name}.md.erb"

assigned_title = title

def find_post_file(name, posts_dir: "_posts")
  Dir.new(posts_dir).entries.each do |filename|
    if /^[0-9]+-[0-9]+-[0-9]+-#{Regexp.escape(name)}\.md/ =~ filename
      return "#{posts_dir}/#{filename}"
    end
  end
  nil
end

names.each do |name|
  title = assigned_title || name
  
  case command
  when :draft
    Dir.mkdir(drafts_dir) unless Dir.exists?(drafts_dir)
    output_file = "#{drafts_dir}/#{name}.md.erb"
    post_time = "<%=post_time%>"
  when :post
    output_file = "#{posts_dir}/#{post_date.strftime("%Y-%m-%d")}-#{name}.md"
  when :publish
    template_file = "#{drafts_dir}/#{name}.md.erb"
    existing_file = find_post_file(name, posts_dir: posts_dir)
    if existing_file
      if create_force
        File.unlink(existing_file)
        STDERR.puts "Deleted #{existing_file}"
      else
        STDERR.puts "#{existing_file} already exists"
        next
      end
    end
    output_file = "#{posts_dir}/#{post_date.strftime("%Y-%m-%d")}-#{name}.md"
  when :republish
    template_file = "#{drafts_dir}/#{name}.md.erb"    
    existing_file = find_post_file(name, posts_dir: posts_dir)
    output_file = existing_file || "#{posts_dir}/#{post_date.strftime("%Y-%m-%d")}-#{name}.md"    
    create_force = true
  end

  unless File.exists?(template_file)
    STDERR.puts "#{template_file} already exists"
    next
  end
  
  if !create_force && File.exists?(output_file)
    STDERR.puts "#{output_file} already exists"
    next
  end
  
  erb = ERB.new(File.read(template_file))
  
  File.write(output_file, erb.result(binding))
  
  STDERR.puts "created #{output_file}"
end
