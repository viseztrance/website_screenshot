spec = Gem::Specification.new do |spec|
  spec.name = "website_screenshot"
  spec.version = "1.0"
  spec.summary = "Takes screenshots of webpages"
  spec.description = <<-EOF
Creates a new webkit window using the QT framework of a specified url and saves a screenshot when the page has finished loading.
EOF

  spec.authors << "Daniel Mircea"
  spec.email = "daniel@viseztrance.com"
  spec.homepage = "http://github.com/viseztrance/website_screenshot"

  spec.files = Dir["{bin,lib,docs}/**/*"] + ["README.rdoc", "LICENSE", "Rakefile", "website_screenshot.gemspec"]
  spec.executables = "website-screenshot"

  spec.has_rdoc = true
  spec.rdoc_options << "--main" << "README.rdoc" << "--title" <<  "Website Screenshot" << "--line-numbers"
                       "--webcvs" << "http://github.com/viseztrance/website_screenshot"
  spec.extra_rdoc_files = ["README.rdoc", "LICENSE"]
end
