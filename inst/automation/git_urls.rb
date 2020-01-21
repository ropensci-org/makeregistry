#!/usr/bin/env ruby

require 'faraday'
require 'json'

puts "making new git urls file: registry_urls.json"

def fetch_gh(org, page, per_page = 100)
  url = 'https://api.github.com/orgs/%s/repos' % org
  resp = Faraday.get(url) do |req|
    req.params['per_page'] = per_page
    req.params['page'] = page.to_s
    req.headers['Authorization'] = 'token ' + ENV['GITHUB_PAT']
    # req.headers['Authorization'] = 'token ' + ENV['GITHUB_PAT_SCOTT']
  end
  return resp
end

# ropensci
res_ropensci = []
(1..5).each do |x|
  res_ropensci << fetch_gh('ropensci', x)
end

# ropenscilabs
res_ropenscilabs = []
(1..3).each do |x|
  res_ropenscilabs << fetch_gh('ropenscilabs', x)
end

ex = File.read("exclude_list.txt").split;
# ex = File.read("/home/ubuntu/exclude_list.txt").split;

# parse JSON and flatten into an array
allres = [res_ropensci, res_ropenscilabs].flatten.map { |x| JSON.load(x.body) }.flatten;

# pull out name and git html (https) url
out = []
allres.each { |repo|
  out << {"repo_name" => repo["name"], "git_url" => repo["html_url"]} unless repo["archived"] || ex.include?(repo["name"])
}

# add other repos (those not in ropensci or ropenscilabs)
nms = ["repo_name", "git_url"]
url = 'https://raw.githubusercontent.com/ropenscilabs/makeregistry/master/inst/automation/not_transferred.txt'
resp = Faraday.get(url)
others = resp.body.split("\n").map{ |z| 
  vals = [z.split("/").last.sub(".git", ""), z]
  Hash[nms.zip(vals)]
}
out.concat others

# write json file to disk
File.open('registry_urls.json', 'w') do |f|
  f.puts(JSON.pretty_generate(out))
end
