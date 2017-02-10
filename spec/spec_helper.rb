$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rdupes'
require 'fileutils'

def add_input(content, *paths)
  destination_directory = File.expand_path(File.join(@dir, *paths))
  FileUtils.mkpath(destination_directory)
  basename = content.gsub(/\W+/, '')[0..20]
  basename = 'unknown' unless basename.size > 0
  file = File.join(destination_directory, basename)
  i = 1
  while File.exists?(file)
    file = File.join(destination_directory, "#{basename}_#{i}")
    i += 1
  end
  File.write(file, content)
  file
end

def should_remain(filename)
  @expected_files_kept << filename
end

def should_go(filename)
  @expected_files_deleted << filename
end

def assert_files
  @expected_files_kept.each do |f|
    expect(File.exist?(f)).to be true
  end
  @expected_files_deleted.each do |f|
    expect(File.exist?(f)).to be false
  end
end
