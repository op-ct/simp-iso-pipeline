# This is the simplest, dumbest implementation imaginable to parse and run a
# .gitlab-ci.yml locally so I can test it without waiting to run an entire ISO
# build, just to find out that I've spelled the next command wrong.

def safe_sh cmds
  unless (ENV.fetch('RUN_VAGRANT','no') == 'yes')
    cmds.gsub!(/^(vagrant|ssh|scp) /m,'echo \0')
  end

  sh cmds
end


def normalized_script(script)
  if script.is_a? Array
    script.map(&:strip).join(" && \\\n")
  else
    script.strip
  end
end


def do_job(job_name,job,job_id)
  Bundler.with_clean_env do

    ENV['CI_JOB_NAME']="dummy_#{job_name}"
    ENV['CI_JOB_ID']="#{job_id}"
    env_vars = ['CI_JOB_NAME','CI_JOB_ID']

    puts "==== JOB: #{job['stage']}/#{job_name}"

    puts "==== #{job['stage']}/#{job_name}: variables"
    job['variables'].each do |k,v|
      ENV[k]=%x{echo #{v}}.strip
      env_vars << k
    end
    env_vars.each { |k| puts "#{k}=#{ENV[k]}" }

    puts "==== #{job['stage']}/#{job_name}: before_script"

    puts "==== #{job['stage']}/#{job_name}: script"
    safe_sh normalized_script(job['before_script']) + "&& \n" + \
            normalized_script(job['script'])

    puts "==== #{job['stage']}/#{job_name}: after_script"
    safe_sh normalized_script(job['after_script'])
    end
  end

def gitlab_ci_dummy_run
  gitlab_ci_yml_path = ENV.fetch(
    'GITLAB_CI_YML_PATH',
    File.expand_path('../.gitlab-ci.yml', File.dirname(__FILE__)),
  )
  unless File.exists? gitlab_ci_yml_path
    warn "WARNING: no GitLab CI config found at '#{gitlab_ci_yml_path}'"
    warn '(skipping)'
    return
  end

  ci = YAML.load_file(gitlab_ci_yml_path)

  ci['stages'].each do |stage|
    jobs    = ci.select{|_name, job| job.class == Hash && job.fetch('stage','') == stage }
    job_id = 1000
    jobs.each do |job_name,job|
      do_job(job_name,job,job_id+=1)
    end
  end
end

namespace :gitlab_ci do
  desc 'Local dummy run using the .gitlab-ci.yml'
  task :dummy_run do
    gitlab_ci_dummy_run
  end
end
