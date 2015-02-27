#!/usr/bin/env ruby
require "date"
require "erb"
require "optparse"

command = ARGV.shift.to_sym

posts_dir = "_posts"
drafts_dir = "_drafts"
erbs_dir = "_erbs"
template_dir = "_template"

output_type = :post
create_force = false
delete_draft = false
update_post = false
post_date = Date.today
title = nil
tags = []
keywords = nil
description = nil
template_name = "default"

op = OptionParser.new

op.on("-f") { create_force = true }
op.on("--delete-draft") { delete_draft = true }
op.on("--update-post") { update_post = true }
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

def extract_filebody(filepath)
  filepath.split(/\//).last.split(/\.md/).first
end

def find_file_for(name, dirpath: ".", strict: false)
  select_files_for(name, dirpath: dirpath, strict: strict).first
end

def select_files_for(name, dirpath: ".", strict: false)
  name = extract_filebody(name)
  Dir.new(dirpath).entries.select do |filename|
    if strict
      /^[0-9]+-[0-9]+-[0-9]+-#{Regexp.escape(name)}\.md/ =~ filename
    else
      /#{Regexp.escape(name)}/ =~ filename
    end
  end.map { |filename| "#{dirpath}/#{filename}" }
end

def post_file_for(name, dirpath: ".", post_date: Date.today)
  name = extract_filebody(name)
  "#{dirpath}/#{post_date.strftime("%Y-%m-%d")}-#{name}.md"
end

def publish(name, input_dir, output_dir, post_date: Date.today, action: :publish, delete: false, force: false, update: false)
  draft_files = select_files_for(name, dirpath: input_dir)
  if draft_files.empty?
    puts "draft file for '#{name}' does not exist"
    return
  end

  draft_files.each do |draft_file|
    existing_file = find_file_for(draft_file, dirpath: output_dir, strict: true)
    post_file = post_file_for(draft_file, dirpath: output_dir, post_date: post_date)
    if update && existing_file
      post_file = existing_file
      force = true
    end

    if force && existing_file && post_file != existing_file
      File.unlink(existing_file)
      puts "Deleted #{existing_file}"
    end

    if !force && File.exists?(post_file)
      puts "#{post_file} already exists"
      next
    end

    if action == :compile
      erb = ERB.new(File.read(draft_file))
      File.write(post_file, erb.result(binding))
    else
      File.copy(draft_file, post_file)
    end

    if existing_file
      puts "Overwrited #{post_file}"
    else
      puts "Created #{post_file}"
    end

    if delete
      File.unlink(draft_file)
      puts "Deleted #{draft_file}"
    end
  end
end

names.each do |name|
  title = assigned_title || name

  case command
  when :new, :draft
    Dir.mkdir(drafts_dir) unless Dir.exists?(drafts_dir)
    draft_file = "#{drafts_dir}/#{name}.md"
    if !create_force && File.exists?(draft_file)
      puts "#{draft_file} already exists"
      next
    end

    erb = ERB.new(File.read(template_file))
    File.write(draft_file, erb.result(binding))
    puts "Created #{draft_file}"
  when :drafts
    draft_files = select_files_for(name, dirpath: drafts_dir)
    draft_files.each do |file|
      puts file
    end
  when :post
    post_file = "#{posts_dir}/#{post_date.strftime("%Y-%m-%d")}-#{name}.md"

    if !create_force && File.exists?(post_file)
      puts "#{post_file} already exists"
      next
    end

    erb = ERB.new(File.read(template_file))
    File.write(post_file, erb.result(binding))
    puts "Created #{post_file}"
  when :publish, :compile
    case command
    when :compile
      input_dir = erbs_dir
    else
      input_dir = drafts_dir
    end

    publish(
      name, input_dir, posts_dir,
      action: command,
      force: create_force,
      delete: delete_draft,
      update: update_post
    )
  end
end
