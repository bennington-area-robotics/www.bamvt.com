require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
load File.expand_path('../last-modified', __dir__)

class LastModifiedTest < Minitest::Test
  SCRIPT = File.expand_path('../last-modified', __dir__)
  OLD = '2026-01-01T12:00:00Z'
  ASCII_ENV = { 'LC_ALL' => 'C', 'LANG' => 'C', 'RUBYOPT' => '-EUS-ASCII' }.freeze

  def setup
    @original = Dir.pwd
    @repo = Dir.mktmpdir('page-timestamps-')
    Dir.chdir(@repo)
    git('init', '-q')
    git('config', 'user.name', 'Timestamp tests')
    git('config', 'user.email', 'timestamps@example.invalid')
    git('config', 'core.hooksPath', '.git/hooks')
    write('index.md', page('Home'))
    write('donate.md', page('Donate', '{% include news.html %} {{ site.data.donations }}'))
    write('_includes/news.html', 'Original news')
    write('_data/donations.json', '{"total": 1}')
    write('_layouts/default.html', '{{ content }}')
    git('add', '.')
    git('commit', '-qm', 'Initial content')
  end

  def teardown
    Dir.chdir(@original)
    FileUtils.remove_entry(@repo)
  end

  def git(*args)
    LastModified.git(*args)
  end

  def write(path, content)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def page(title, body = 'Original body', extra = '', layout: 'default')
    "---\nlayout: #{layout}\ntitle: #{title}\nlast_modified_at: #{OLD}\n#{extra}---\n#{body}\n"
  end

  def run_hook
    output, error, status = Open3.capture3('ruby', SCRIPT, '--staged')
    assert status.success?, "#{output}\n#{error}"
  end

  def test_real_commit_preserves_partially_staged_content
    write('.git/hooks/pre-commit', "#!/bin/sh\nexec ruby '#{SCRIPT}' --staged\n")
    File.chmod(0o755, '.git/hooks/pre-commit')
    write('index.md', page('Home', 'Staged body'))
    git('add', 'index.md')
    write('index.md', page('Home', 'Staged body plus unstaged work'))
    git('commit', '-qm', 'Edit home')
    committed = git('show', 'HEAD:index.md')
    assert_includes committed, 'Staged body'
    refute_includes committed, 'unstaged work'
    assert_includes File.read('index.md'), 'unstaged work'
    assert_equal LastModified.timestamp(committed), LastModified.timestamp(File.read('index.md'))
    assert_equal '', git('diff', '--cached')
    assert LastModified.timestamp(committed) > Time.iso8601(OLD)
    LastModified.check('HEAD^', 'HEAD')
  end

  def test_shared_data_updates_consumer_but_does_not_stage_its_edits
    write('_data/donations.json', '{"total": 2}')
    git('add', '_data/donations.json')
    File.open('donate.md', 'a') { |f| f.puts 'Unstaged copy' }
    run_hook
    refute_includes git('show', ':donate.md'), 'Unstaged copy'
    assert_includes File.read('donate.md'), 'Unstaged copy'
    assert_equal Time.iso8601(OLD), LastModified.timestamp(git('show', ':index.md'))
    assert LastModified.timestamp(git('show', ':donate.md')) > Time.iso8601(OLD)
  end

  def test_ascii_locale_commit_preserves_utf8_and_partially_staged_content
    write('.git/hooks/pre-commit', "#!/bin/sh\nexec ruby '#{SCRIPT}' --staged\n")
    File.chmod(0o755, '.git/hooks/pre-commit')
    staged_body = 'Café — students’ robots'
    unstaged_body = "#{staged_body}\nUnstaged résumé"
    write('index.md', page('Équipe', staged_body))
    git('add', 'index.md')
    write('index.md', page('Équipe', unstaged_body))

    output, error, status = Open3.capture3(ASCII_ENV, 'git', 'commit', '-qm', 'UTF-8 content')
    assert status.success?, "#{output}\n#{error}"
    committed = git('show', 'HEAD:index.md')
    assert_equal LastModified.without_stamp(page('Équipe', staged_body)), LastModified.without_stamp(committed)
    assert_equal LastModified.without_stamp(page('Équipe', unstaged_body)), LastModified.without_stamp(File.read('index.md'))
    assert_equal LastModified.timestamp(committed), LastModified.timestamp(File.read('index.md'))
    assert LastModified.timestamp(committed) > Time.iso8601(OLD)
    assert_equal '', git('diff', '--cached')

    output, error, status = Open3.capture3(ASCII_ENV, 'ruby', SCRIPT, '--check', 'HEAD^', 'HEAD')
    assert status.success?, "#{output}\n#{error}"
  end

  def test_ascii_locale_backfill_preserves_utf8
    source = LastModified.without_stamp(page('Équipe', 'Café — students’ robots'))
    write('index.md', source)
    git('add', 'index.md')
    git('commit', '-qm', 'UTF-8 page without timestamp')
    output, error, status = Open3.capture3(ASCII_ENV, 'ruby', SCRIPT, '--backfill')
    assert status.success?, "#{output}\n#{error}"
    updated = File.read('index.md')
    assert_equal source, LastModified.without_stamp(updated)
    assert LastModified.timestamp(updated)
    assert_equal '', git('diff', '--cached')
  end

  def test_commit_only_is_rejected_without_changing_either_index
    write('.git/hooks/pre-commit', "#!/bin/sh\nexec ruby '#{SCRIPT}' --staged\n")
    File.chmod(0o755, '.git/hooks/pre-commit')
    write('index.md', page('Home', 'Unrelated staged edit'))
    git('add', 'index.md')
    write('_data/donations.json', '{"total": 2}')
    staged = git('diff', '--cached')
    working = File.read('donate.md')
    error = assert_raises(RuntimeError) do
      git('commit', '--only', '-qm', 'Update donations', '--', '_data/donations.json')
    end
    assert_includes error.message, 'without file/path arguments'
    refute_includes git('show', 'HEAD:index.md'), 'Unrelated staged edit'
    assert_includes git('show', ':index.md'), 'Unrelated staged edit'
    assert_equal staged, git('diff', '--cached')
    assert_equal working, File.read('donate.md')
  end


  def test_deleted_include_updates_consumer
    git('rm', '_includes/news.html')
    run_hook
    assert LastModified.timestamp(git('show', ':donate.md')) > Time.iso8601(OLD)
  end

  def test_layout_and_embed_changes_leave_dates_unchanged
    write('_layouts/default.html', '<main>{{ content }}</main>')
    write('_includes/video.html', '<iframe></iframe>')
    git('add', '.')
    run_hook
    assert_equal Time.iso8601(OLD), LastModified.timestamp(git('show', ':index.md'))
    assert_equal Time.iso8601(OLD), LastModified.timestamp(git('show', ':donate.md'))
  end

  def test_timestamp_only_change_does_not_cascade
    write('index.md', LastModified.stamp(File.read('index.md'), '2026-02-01T12:00:00Z'))
    git('add', 'index.md')
    before = git('diff', '--cached')
    run_hook
    assert_equal before, git('diff', '--cached')
  end

  def test_new_page_gets_timestamp_and_renamed_page_is_supported
    write('new.md', "---\nlayout: default\n---\nNew page\n")
    git('mv', 'index.md', 'renamed.md')
    git('add', 'new.md')
    run_hook
    assert LastModified.timestamp(git('show', ':new.md'))
    assert LastModified.timestamp(git('show', ':renamed.md')) > Time.iso8601(OLD)
  end



  def test_ci_catches_bypassed_hook_and_supports_repair
    write('_includes/news.html', 'New news')
    git('add', '.')
    git('commit', '-qm', 'Bypass hook')
    error = assert_raises(RuntimeError) { LastModified.check('HEAD^', 'HEAD') }
    assert_includes error.message, 'donate.md: content changed'
    LastModified.update_index('HEAD^')
    git('commit', '-qm', 'Repair timestamp')
    LastModified.check('HEAD~2', 'HEAD')
  end

  def test_ci_rejects_missing_timestamp
    write('index.md', LastModified.without_stamp(File.read('index.md')))
    git('add', '.')
    git('commit', '-qm', 'Remove timestamp')
    assert_raises(RuntimeError) { LastModified.check('HEAD^', 'HEAD') }
  end

  def test_missing_working_file_aborts_before_any_mutation
    write('_includes/news.html', 'New news')
    git('add', '.')
    File.delete('donate.md')
    before = git('diff', '--cached')
    assert_raises(RuntimeError) { LastModified.update_index }
    assert_equal before, git('diff', '--cached')
  end

  def test_backfill_uses_history_and_is_idempotent
    write('index.md', LastModified.without_stamp(File.read('index.md')))
    git('add', '.')
    git('commit', '-qm', 'Page without timestamp')
    expected = git('log', '-1', '--format=%cI', '--', 'index.md').strip
    LastModified.backfill
    assert_equal Time.iso8601(expected), LastModified.timestamp(File.read('index.md'))
    before = File.read('index.md')
    LastModified.backfill
    assert_equal before, File.read('index.md')
    assert_equal '', git('diff', '--cached')
  end

  def test_backfill_initializes_untracked_pages_without_staging_them
    write('new.md', "---\nlayout: default\n---\nNew page\n")
    LastModified.backfill
    assert LastModified.timestamp(File.read('new.md'))
    assert_equal '', git('diff', '--cached')
    assert_includes git('ls-files', '--others', '--exclude-standard'), 'new.md'
  end

  def test_metadata_only_change_does_not_advance_date
    write('index.md', page('Home', 'Original body', "description: New summary\nsitemap: false\n"))
    git('add', 'index.md')
    run_hook
    assert_equal Time.iso8601(OLD), LastModified.timestamp(git('show', ':index.md'))
  end

  def test_title_and_event_details_are_content
    write('index.md', page('New home title'))
    write('_events/talk.md', page('Talk', 'Body', "event_start: '2020-03-21 10:00:00'\n", layout: 'event'))
    git('add', '.')
    run_hook
    assert LastModified.timestamp(git('show', ':index.md')) > Time.iso8601(OLD)
    assert LastModified.timestamp(git('show', ':_events/talk.md'))
  end

  def test_event_layout_data_updates_event_pages_only
    write('_events/talk.md', page('Talk', 'Body', "venue_id: '1'\n", layout: 'event'))
    write('_data/event_venues.json', '{"1": {"name": "Shop"}}')
    git('add', '.')
    git('commit', '-qm', 'Add event')
    write('_data/event_venues.json', '{"1": {"name": "New shop"}}')
    git('add', '_data')
    run_hook
    assert LastModified.timestamp(git('show', ':_events/talk.md')) > Time.iso8601(OLD)
    assert_equal Time.iso8601(OLD), LastModified.timestamp(git('show', ':index.md'))
  end

  def test_unused_event_data_entries_leave_event_dates_unchanged
    write('_events/talk.md', page('Talk', 'Body', "venue_id: '1'\n", layout: 'event'))
    write('_data/event_venues.json', '{"1": {"name": "Shop"}, "2": {"name": "Unused"}}')
    git('add', '.')
    git('commit', '-qm', 'Add event')
    write('_data/event_venues.json', '{"1": {"name": "Shop"}}')
    git('add', '_data')
    run_hook
    assert_equal Time.iso8601(OLD), LastModified.timestamp(git('show', ':_events/talk.md'))
  end

  def test_backfill_ignores_unused_event_data_entries
    write('_events/talk.md', LastModified.without_stamp(page('Talk', 'Body', "venue_id: '1'\n", layout: 'event')))
    write('_data/event_venues.json', '{"1": {"name": "Shop"}, "2": {"name": "Unused"}}')
    git('add', '.')
    git('commit', '-qm', 'Add event')
    content_date = git('log', '-1', '--format=%cI').strip
    write('_data/event_venues.json', '{"1": {"name": "Shop"}}')
    git('add', '.')
    env = { 'GIT_COMMITTER_DATE' => '2030-01-01T00:00:00Z' }
    output, error, status = Open3.capture3(env, 'git', 'commit', '-qm', 'Prune venues')
    assert status.success?, "#{output}\n#{error}"
    LastModified.backfill
    assert_equal Time.iso8601(content_date), LastModified.timestamp(File.read('_events/talk.md'))
  end

  def test_archive_list_data_updates_listing
    write('events/index.md', page('Events', '{% include archive-list.html ids=page.archive_ids %}'))
    write('_includes/archive-list.html', '{{ site.data.legacy_content[id] }}')
    write('_data/legacy_content.json', '{}')
    git('add', '.')
    git('commit', '-qm', 'Add listing')
    write('_data/legacy_content.json', '{"1": {"title": "Talk"}}')
    git('add', '_data')
    run_hook
    assert LastModified.timestamp(git('show', ':events/index.md')) > Time.iso8601(OLD)
  end

  def test_backfill_skips_metadata_only_commits
    write('index.md', LastModified.without_stamp(File.read('index.md')))
    git('add', '.')
    git('commit', '-qm', 'Remove timestamp')
    content_date = git('log', '-1', '--format=%cI', '--', 'index.md').strip
    text = File.read('index.md').sub("title: Home\n", "title: Home\ndescription: Summary\n")
    write('index.md', text)
    git('add', '.')
    env = { 'GIT_COMMITTER_DATE' => '2030-01-01T00:00:00Z' }
    output, error, status = Open3.capture3(env, 'git', 'commit', '-qm', 'Add description')
    assert status.success?, "#{output}\n#{error}"
    LastModified.backfill
    assert_equal Time.iso8601(content_date), LastModified.timestamp(File.read('index.md'))
  end

  def test_unlisted_layouts_are_not_stamped
    write('feed.html', "---\nlayout: null\n---\nFeed")
    git('add', '.')
    run_hook
    refute_includes git('show', ':feed.html'), 'last_modified_at'
  end
end
