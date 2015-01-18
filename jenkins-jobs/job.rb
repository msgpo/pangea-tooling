require 'erb'
require 'pathname'

require_relative '../ci-tooling/lib/jenkins'

# Base class for Jenkins jobs.
class JenkinsJob
  # FIXME: redundant should be name
  attr_reader :job_name

  attr_reader :template_path

  def initialize(job_name, template_name)
    @job_name = job_name
    file_directory = File.expand_path(File.dirname(__FILE__))
    @template_directory = "#{file_directory}/templates/"
    @template_path = "#{@template_directory}#{template_name}"
    fail "Template #{template_name} not found" unless File.exist?(@template_path)
  end

  # Creates or updates the Jenkins job.
  # @return the job_name
  def update
    xml = render(@template_path)
    begin
      print "Updating #{job_name}\n"
      Jenkins.job.create_or_update(job_name, xml)
    rescue => e
      puts e
      retry
    end
    job_name
  end

  def render(path)
    if Pathname.new(path).absolute?
      data = File.read(path)
    else
      data = File.read("#{@template_directory}/#{path}")
    end
    ERB.new(data).result(binding)
  end
end
