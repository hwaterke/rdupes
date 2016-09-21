require "rdupes/version"
require 'logger'
require 'shellwords'

module Rdupes
  class Finder
    attr_reader :logger

    def initialize
      @logger = Logger.new(STDOUT)
      @logger.level = Logger::WARN
      @reference_directories = []
      @search_directories = []
      @counters = Hash.new(0)
      @quiet = false
    end

    def quiet!
      @quiet = true
    end

    def add_reference_directory(directory)
      directory_path = File.expand_path(directory)
      @logger.debug "Adding #{directory_path} to the reference directories"
      raise "#{directory_path} does not exist" unless Dir.exist?(directory_path)
      @reference_directories << directory_path
      @reference_directories.uniq!
    end

    def add_search_directory(directory)
      directory_path = File.expand_path(directory)
      @logger.debug "Adding #{directory_path} to the search directories"
      raise "#{directory_path} does not exist" unless Dir.exist?(directory_path)
      @search_directories << directory_path
      @search_directories.uniq!
    end

    def process(directories)
      @search_directories.clear
      directories.each { |d| add_search_directory(d) }
      raise 'No directories provided for duplicate search' if @search_directories.empty?
      raise 'fdupes needs to be installed' unless command? 'fdupes'

      unless @quiet
        puts "Processing #{@search_directories}"
        puts "Reference directory: #{@reference_directories}"
      end

      # Redirect to file
      cmd = "fdupes -rq #{directories_for_search.shelljoin} > duplicates.log"
      @logger.debug "Executing: #{cmd}"
      r = system cmd
      raise "fdupe crashed " unless r
      process_fdupes_result('duplicates.log')
      puts "Deleted #{@counters[:deleted]} files" unless @quiet
    end

    private

    def command?(command)
      system("which #{ command} > /dev/null 2>&1")
    end

    def directories_for_search
      (@reference_directories + @search_directories).uniq
    end

    def process_fdupes_result(fdupes_output_file)
      @logger.debug "Handling fdupes result #{fdupes_output_file}"
      current_group = []
      File.open(fdupes_output_file).each do |line|
        line.chomp!
        if line.empty?
          handle_duplicate_group(current_group)
          current_group = []
        else
          current_group << line
        end
      end
    end

    def handle_duplicate_group(duplicate_group)
      @logger.debug "Handling group of #{duplicate_group.size} duplicates"
      reference_files, duplicate_files = duplicate_group.partition do |f|
        @reference_directories.any? { |rf| File.expand_path(f).start_with?(rf) }
      end
      # Keep the first duplicate if there is no reference file.
      duplicate_files.shift if reference_files.empty?
      duplicate_files.each { |dp| handle_duplicate_file(dp) }
    end

    def handle_duplicate_file(duplicate_file)
      @counters[:deleted] += 1
      @logger.debug "Handling duplicate #{duplicate_file}"
      File.delete(duplicate_file)
    end
  end
end
