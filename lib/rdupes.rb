require "rdupes/version"
require 'logger'
require 'shellwords'
require 'tmpdir'
require 'colorize'

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
      @keep = false
      @dry_run = false
    end

    def quiet!
      @logger.debug "Enabling quiet mode"
      @quiet = true
    end

    def keep!
      @logger.debug "Enabling keep mode. Will keep the fdupes output"
      @keep = true
    end

    def dry_run!
      @logger.debug "Enabling dry run mode"
      @dry_run = true
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

      say "Processing #{@search_directories}"
      say "Reference directory: #{@reference_directories}"

      Dir.mktmpdir do |dir|
        fdupes_output = File.join(dir, 'duplicates.log')
        # Redirect to file
        cmd = "fdupes -rq #{directories_for_search.shelljoin} > #{fdupes_output}"
        @logger.debug "Executing: #{cmd}"
        r = system cmd
        raise "fdupe crashed " unless r
        process_fdupes_result(fdupes_output)

        if @keep
          fdupes_output_copy = "#{Time.now.strftime('%Y-%m-%d_%H-%M-%S')}_duplicates.log"
          say "Copying fdupes result to #{fdupes_output_copy}"
          FileUtils.cp fdupes_output, fdupes_output_copy
        end

        say "Found #{@counters[:duplicate_groups]} duplicate groups"
        say "Found #{@counters[:duplicate_entries]} duplicate entries"
        say "Flagged #{@counters[:flag_for_delete]} files for deletion"
        say "Deleted #{@counters[:deleted]} files"
      end
    end

    private

    def say(text)
      puts text unless @quiet
    end

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
      say "#{'==>'.blue} Group of #{duplicate_group.size} duplicates"
      @counters[:duplicate_groups] += 1
      @counters[:duplicate_entries] += duplicate_group.size
      reference_files, duplicate_files = duplicate_group.partition do |f|
        @reference_directories.any? { |rf| File.expand_path(f).start_with?(rf) }
      end
      # Keep the first duplicate if there is no reference file.
      say "- #{duplicate_files.shift}".green if reference_files.empty?
      reference_files.each { |rf| say "- #{rf}".green }
      duplicate_files.each { |dp| handle_duplicate_file(dp) }
    end

    def handle_duplicate_file(duplicate_file)
      @logger.debug "Handling duplicate #{duplicate_file}"
      @counters[:flag_for_delete] += 1
      say "- #{duplicate_file}".red
      unless @dry_run
        File.delete(duplicate_file)
        @counters[:deleted] += 1
      end
    end
  end
end
