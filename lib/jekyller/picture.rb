require "jekyller"
require "fileutils"
require "rmagick"
require "mini_exiftool"

module Jekyller
  class Picture
    attr_accessor :filepath
    attr_reader :image, :exif, :stat, :errors

    def initialize(filepath)
      @filepath = filepath
      @image = Magick::Image.read(filepath).first
      @exif = MiniExiftool.new(filepath)
      @stat = File.stat(filepath)
      @errors = []
    end

    def resize_to_fit!(width, height)
      @image = image.resize_to_fit(width, height)
    end

    def save(options = {})
      dirpath = File.dirname(filepath)
      Dir.mkdir(dirpath) unless Dir.exists?(dirpath)

      if options[:force] && File.exists?(filepath)
        File.unlink(filepath) 
        puts "Deleted #{filepath}" if options[:verbose]
      end

      if File.exists?(filepath)
        errors << "#{filepath} already exists"
        return false
      end

      image.write(filepath)
      puts "Created #{filepath}" if options[:verbose]

      if options[:exif]
        output_exif = MiniExiftool.new(filepath)
        exif.tags.each do |key|
          output_exif[key] = exif[key]
        end
        output_exif.save

        puts "Updated EXIF: #{filepath}" if options[:verbose]
      end

      if options[:stat]
        File::utime(stat.atime, stat.mtime, filepath)
        puts "Updated stat: #{filepath}" if options[:verbose]
      end

      true
    end
  end
end
