require 'spec_helper'

describe Rdupes do
  it 'has a version number' do
    expect(Rdupes::VERSION).not_to be nil
  end

  it 'can be instantiated' do
    expect(Rdupes::Finder.new).not_to be nil
  end

  describe 'finder' do

    before(:each) do
      @finder = Rdupes::Finder.new
      @finder.logger.level = Logger::DEBUG

      # Create temp directory
      @dir = Dir.mktmpdir

      # Variables to store which files should be kept and deleted
      @expected_files_kept = []
      @expected_files_deleted = []
    end

    after(:each) do
      # Clean temp directory
      FileUtils.remove_entry @dir
    end

    describe 'without reference directory' do

      it 'keeps different file' do
        should_remain add_input 'hello'
        should_remain add_input 'world'
        @finder.process([@dir])
        assert_files
      end

      it 'keeps one copy out of two' do
        should_remain add_input 'hello'
        should_go add_input 'hello'
        @finder.process([@dir])
        assert_files
      end

      it 'keeps one copy out of ten' do
        should_remain add_input 'hello'
        9.times { should_go add_input 'hello' }
        @finder.process([@dir])
        assert_files
      end

      it 'works with subdirectories' do
        should_remain add_input 'hello', 'a', 'b', 'c'
        should_go add_input 'hello', 'z', 'y', 'x'
        @finder.process([@dir])
        assert_files
      end

      it 'works with multiple groups of duplicates' do
        should_remain add_input 'one'
        should_remain add_input 'two'
        should_remain add_input 'three'
        should_go add_input 'one'
        should_go add_input 'one'
        should_go add_input 'two'
        @finder.process([@dir])
      end

      it 'works when repeating input folders' do
        should_remain add_input 'one', 'a', 'b', 'c'
        should_remain add_input 'two', 'a', 'b', 'c'
        should_remain add_input 'three', 'a', 'b', 'c'
        should_go add_input 'one', 'z', 'y', 'x'
        should_go add_input 'one', 'zz', 'yy'
        should_go add_input 'two', 'yy', 'yy'
        @finder.process([@dir, @dir, @dir])
        assert_files
      end
    end

    describe 'with reference directory' do

      it 'keeps all files in reference_directories' do
        should_remain add_input 'one', 'b'
        should_remain add_input 'one', 'b', 'a'
        should_remain add_input 'one', 'b', 'b'
        should_remain add_input 'one', 'b', 'c'
        should_remain add_input 'two', 'b', 'y'
        should_remain add_input 'two', 'b', 'z'
        @finder.add_reference_directory File.join(@dir, 'b')
        @finder.process([@dir])
        assert_files
      end

      it 'keeps copy in reference directory' do
        should_go add_input 'hello', 'a'
        should_remain add_input 'hello', 'b'
        @finder.add_reference_directory File.join(@dir, 'b')
        @finder.process([@dir])
        assert_files
      end

      it 'keeps copy in reference directory, deletes all copies outside' do
        should_go add_input 'hello', 'a'
        should_go add_input 'hello', 'a', 'x'
        should_go add_input 'hello', 'a', 'y'
        should_go add_input 'hello', 'a', 'z'
        should_remain add_input 'hello', 'b'
        should_remain add_input 'hello', 'b', 'a'
        @finder.add_reference_directory File.join(@dir, 'b')
        @finder.process([@dir])
        assert_files
      end
    end
  end
end
