# frozen_string_literal: true

require 'spec_helper'
require 'bolt/pal/yaml_plan/transpiler'
require 'bolt_spec/config'
require 'bolt_spec/integration'

describe "transpiling YAML plans" do
  include BoltSpec::Config
  include BoltSpec::Integration

  after(:each) { Puppet.settings.send(:clear_everything_for_tests) }
  let(:modulepath) { fixture_path('modules') }
  let(:yaml_path) { File.join(modulepath, 'yaml', 'plans') }
  let(:plan_path) { File.join(yaml_path, 'conversion.yaml') }
  let(:output_plan) { <<~PLAN }
  # WARNING: This is an autogenerated plan. It may not behave as expected.
  plan yaml::conversion(
    TargetSpec $nodes,
    String $message = 'hello world'
  ) {
    $sample = run_task('sample', $nodes, {'message' => $message})
    apply_prep($nodes)
    apply($nodes) {
      package { 'nginx': }
      ->
      file { '/etc/nginx/html/index.html':
        content => "Hello world!",
      }
      ->
      service { 'nginx': }
    }
    $eval_output = with() || {
      # TODO: Can blocks handle comments?
      $list = $sample.targets.map |$t| {
        notice($t)
        $t
      }
      $list.map |$l| {$l.name}
    }

    return $eval_output
  }
  PLAN

  it 'transpiles a yaml plan' do
    expect {
      run_cli(['plan', 'convert', plan_path])
    }.to output(output_plan).to_stdout
  end
end