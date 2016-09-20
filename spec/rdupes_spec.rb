require "spec_helper"

describe Rdupes do
  it "has a version number" do
    expect(Rdupes::VERSION).not_to be nil
  end

  it 'can be instantiated' do
    expect(Rdupes::Finder.new).not_to be nil
  end
end
