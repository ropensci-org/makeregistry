#!/usr/bin/env ruby

require 'octokit'

ex = File.read("../../inst/automation/exclude_list.txt").split
org = ARGV[0]
url = "https://api.github.com/orgs/%s/repos" % org

# fetch json
con = Octokit::Client.new :access_token => ENV['GITHUB_PAT']
res = con.org_repositories(org, :per_page => 100);
out = []
out << res;
last_res = con.last_response;
until last_res.rels[:next].nil?
  last_res = last_res.rels[:next].get;
  out << last_res.data;
end
out.flatten!;

# clone repos
out.each { |repo|
  puts repo["name"]
  %x[git clone --depth 1 #{repo["html_url"]}] unless File.directory?(repo["name"]) || repo["archived"] || repo["fork"] || ex.include?(repo["name"])
}
