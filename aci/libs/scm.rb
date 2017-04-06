require_relative 'metadata'
require 'fileutils'
require 'rugged'

# Module for source control
module SCM
  def self.git_clone_source(args = {})
    url = args[:url]
    branch = args[:branch]
    dir = args[:dir]
    Rugged::Repository.clone_at(url, dir, checkout_branch: branch)
  end
end