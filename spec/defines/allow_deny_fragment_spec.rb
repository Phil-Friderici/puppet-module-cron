require 'spec_helper'
describe 'cron::allow_deny_fragment' do

  let(:title) { 'rspec-test' }
  let(:facts) do
    {
      :osfamily               => 'RedHat',
      :operatingsystemrelease => '7.5',
      :concat_basedir         => '/concat/basedir', # concat
      :id                     => 'root',            # concat
      :kernel                 => 'Linux',           # concat
      :path                   => '/usr/bin:/bin',   # concat
    }
  end

  mandatory_params = {
    :users => %w(user1 user2),
    :type  => 'allow',
  }

  describe 'with default values for parameters' do
    it 'should fail' do
      expect { should contain_class(subject) }.to raise_error(Puppet::Error, /(Must pass|expects a value for parameter)/) # (Puppet 3|Puppet >3)
    end
  end

  describe 'with mandatory params set to valid values' do
    let(:params) { mandatory_params }

    concat_fragment = <<-END.gsub(/^\s+\|/, '')
      |
      |# rspec-test
      |user1
      |user2
    END
    it { should contain_class('cron') }
    it do
      should contain_concat__fragment('rspec-test').with({
        'target'  => '/etc/cron.allow',
        'order'   => '02',
        'content' => concat_fragment,
      })
    end
  end

  describe 'with users set to %w(user1) when mandatory parameters are set' do
    let(:params) { mandatory_params.merge({ :users => %w(user1) }) }
    it { should contain_concat__fragment('rspec-test').with_content("\n# rspec-test\nuser1\n") }
  end

  describe 'with users set to %w(user1 user2) when mandatory parameters are set' do
    let(:params) { mandatory_params.merge({ :users => %w(user1 user2) }) }
    it { should contain_concat__fragment('rspec-test').with_content("\n# rspec-test\nuser1\nuser2\n") }
  end

  describe 'with users set to multidimensional array when mandatory parameters are set' do
    let(:params) { mandatory_params.merge({ :users => ['user1',['user2',['user3']]] }) }
    it { should contain_concat__fragment('rspec-test').with_content("\n# rspec-test\nuser1\nuser2\nuser3\n") }
  end

  describe 'with type set to valid string deny when mandatory parameters are set' do
    let(:params) { mandatory_params.merge({ :type => 'deny' }) }
    it { should contain_concat__fragment('rspec-test').with_target('/etc/cron.deny') }
  end

  describe 'variable type and content validations' do
    validations = {
      'array' => {
        :name    => %w(users),
        :valid   => [%w(array)],
        :invalid => ['string',{ 'ha' => 'sh' }, 3, 2.42, false, nil],
        :message => 'is not an Array',
      },
      'regex_type' => {
        :name    => %w(type),
        :valid   => %w(allow deny),
        :invalid => ['string', %w[array], { 'ha' => 'sh' }, 3, 2.42, false, nil],
        :message => 'must be allow or deny',
      },
    }

    validations.sort.each do |type, var|
      mandatory_params = {} if mandatory_params.nil?
      var[:name].each do |var_name|
        var[:params] = {} if var[:params].nil?
        var[:valid].each do |valid|
          context "when #{var_name} (#{type}) is set to valid #{valid} (as #{valid.class})" do
            let(:params) { [mandatory_params, var[:params], { :"#{var_name}" => valid, }].reduce(:merge) }
            it { should compile }
          end
        end

        var[:invalid].each do |invalid|
          context "when #{var_name} (#{type}) is set to invalid #{invalid} (as #{invalid.class})" do
            let(:params) { [mandatory_params, var[:params], { :"#{var_name}" => invalid, }].reduce(:merge) }
            it 'should fail' do
              expect { should contain_class(subject) }.to raise_error(Puppet::Error, /#{var[:message]}/)
            end
          end
        end
      end # var[:name].each
    end # validations.sort.each
  end # describe 'variable type and content validations'
end
