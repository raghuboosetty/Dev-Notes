def expire_jobs_test
  load_time = Benchmark.realtime do
    count = 0
    Source.where("crawl_profile_id is NOT NULL").where("jobs_count > 0").where("source_type IN (?)", [Source::TYPES[:job_board], Source::TYPES[:employer]]).where("sources.id NOT IN (#{CrawlerJobStat.expire.queued_sources.to_sql})").each do |source|
      j_count = source.jobs.where("created_at < ?", 60.days.ago).count
      puts "#{source.name} - #{j_count}"
      count += j_count
    end
    puts "Total Count : #{count}"
  end
  puts "Total RealTime : #{load_time}ms"
end
expire_jobs_test



def expire_jobs_test
  load_time = Benchmark.realtime do
    count = 0
    Source.where("jobs_count > 0").
           where("source_type IN (?)", [ Source::TYPES[:job_board], Source::TYPES[:employer] ]).
           where("sources.id NOT IN (#{CrawlerJobStat.expire.queued_sources.to_sql})").each do |source|

      puts "#{ source.id } - #{source.name} - before enqueue"

      first_job = source.jobs.first
      next if !first_job

      if ((source.source_type == Source::TYPES[:job_board]) && (first_job.created_at < 30.days.ago))
        j_count = source.jobs.where("created_at < ?", 30.days.ago).count
         puts "#{source.name} - #{j_count}"
         count += j_count
      end

      if ((source.source_type == Source::TYPES[:employer]) && (first_job.created_at < 60.days.ago))
          j_count = source.jobs.where("created_at < ?", 60.days.ago).count
          puts "#{source.name} - #{j_count}"
          count += j_count
      end
    end # Source
    puts "Total Count : #{count}"
  end # Benchmark
  puts "Total RealTime : #{load_time}"
end # def schedule