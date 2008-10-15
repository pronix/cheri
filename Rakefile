require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/packagetask'
require 'rake/gempackagetask'
require 'rake/contrib/rubyforgepublisher'
require 'fileutils'
require File.join(File.dirname(__FILE__), 'lib', 'cheri', 'cheri')

PKG_BUILD     = ENV['PKG_BUILD'] ? '.' + ENV['PKG_BUILD'] : ''
PKG_NAME      = 'cheri'
PKG_VERSION   = Cheri::VERSION::STRING + PKG_BUILD
PKG_FILE_NAME   = "#{PKG_NAME}-#{PKG_VERSION}"
PKG_DESTINATION = "../#{PKG_NAME}"

RELEASE_NAME  = "REL #{PKG_VERSION}"

RUBY_FORGE_PROJECT = "cheri"
RUBY_FORGE_USER    = "bill_dortch"

desc "Default Task"
#task :default => [ :test ]
task :default => [ :gem ]


# Run the unit tests
Rake::TestTask.new { |t|
  t.libs << "test"
  t.test_files = Dir['test/*_test.rb']
  t.verbose = true
}

# Generate the RDoc documentation
Rake::RDocTask.new { |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = "Cheri Builder Platform"
  #rdoc.options << '--all'
  #rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.template = "#{ENV['template']}.rb" if ENV['template']
  rdoc.rdoc_files.include('README')
  #rdoc.rdoc_files.include('CHANGELOG')
  rdoc.rdoc_files.include("lib/**/*.rb")
}


# Create compressed packages
spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = PKG_NAME
  s.summary = "Cheri Builder Platform"
  s.description = %q{The Cheri Builder Platform.}
  s.version = PKG_VERSION

  s.author = "Bill Dortch"
  s.email = "cheri.project@gmail.com"
  s.rubyforge_project = "cheri"
  s.homepage = "http://cheri.rubyforge.org"

  s.has_rdoc = true
  s.requirements << 'none'
  s.require_path = 'lib'

  s.files = [ "Rakefile", "README", "MIT-LICENSE" ]
  s.files = s.files + Dir.glob( "examples/**/*" ).delete_if { |item| item.include?( "\.svn" ) }
  s.files = s.files + Dir.glob( "lib/**/*" ).delete_if { |item| item.include?( "\.svn" ) }
  s.files = s.files + Dir.glob( "test/**/*" ).delete_if { |item| item.include?( "\.svn" ) }
end
Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar = true
  p.need_zip = true
end


def each_source_file(*args)
	prefix, includes, excludes, open_file = args
	prefix ||= File.dirname(__FILE__)
	open_file = true if open_file.nil?
	includes ||= %w[lib\/cheri\.rb$ lib\/cheri\/.*\.rb$]
	Find.find(prefix) do |file_name|
		next if file_name =~ /\.svn/
		file_name.gsub!(/^\.\//, '')
		continue = false
		includes.each do |inc|
			if file_name.match(/#{inc}/)
				continue = true
				break
			end
		end
		next unless continue
		if open_file
			File.open(file_name) do |f|
				yield file_name, f
			end
		else
			yield file_name
		end
	end
end

desc "Count lines of the Cheri source code"
task :lines do
  total_lines = total_loc = 0
  puts "Per File:"
	each_source_file do |file_name, f|
    file_lines = file_loc = 0
    while line = f.gets
      file_lines += 1
      next if line =~ /^\s*$/
      next if line =~ /^\s*#/
      file_loc += 1
    end
    puts "  #{file_name}: Lines #{file_lines}, LOC #{file_loc}"
    total_lines += file_lines
    total_loc += file_loc
  end
  puts "Total:"
  puts "  Lines #{total_lines}, LOC #{total_loc}"
end

