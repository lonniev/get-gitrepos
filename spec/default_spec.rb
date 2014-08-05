require 'chefspec'

describe 'get-gitrepos::default' do
  
  let(:chef_run) do
    runner = ChefSpec::ChefRunner.new('platform' => 'ubuntu', 'version'=> '12.04')
    runner.converge('get-gitrepos::default')
  end
    
  it 'should include the get-gitrepos recipe by default' do
    expect(chef_run).to include_recipe 'get-gitrepos::default'
  end

end
