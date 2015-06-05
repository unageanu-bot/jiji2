# coding: utf-8

require 'jiji/test/test_configuration'

describe Jiji::Model::Trading::PositionRepository do
  before(:example) do
    @data_builder = Jiji::Test::DataBuilder.new

    factory = Jiji::Test::TestContainerFactory.instance

    @container            = factory.new_container
    @backtest_repository  = @container.lookup(:backtest_repository)
    @position_repository  = @container.lookup(:position_repository)
    @time_source          = @container.lookup(:time_source)
    @registory            = @container.lookup(:agent_registry)

    @registory.add_source('aaa', '', :agent, @data_builder.new_agent_body(1))

    @test1 = @data_builder.register_backtest(1, @backtest_repository)
    @test2 = @data_builder.register_backtest(2, @backtest_repository)
    @test3 = @data_builder.register_backtest(3, @backtest_repository)

    register_rmt_positions
    register_backtest_positions(@test1._id)
    register_backtest_positions(@test2._id)
  end

  after(:example) do
    @data_builder.clean
  end

  def register_rmt_positions
    register_positions(nil)
  end

  def register_backtest_positions(backtest_id)
    register_positions(backtest_id)
  end

  def register_positions(backtest_id)
    100.times do |i|
      position = @data_builder.new_position(i, backtest_id)
      position.save
      position.update_state_to_closed if i < 50
    end
  end

  it 'ソート条件、取得数を指定して、一覧を取得できる' do
    positions = @position_repository.retrieve_positions(nil)

    expect(positions.length).to eq(20)
    expect(positions[0].backtest_id).to eq(nil)
    expect(positions[0].entered_at).to eq(Time.at(0))
    expect(positions[19].backtest_id).to eq(nil)
    expect(positions[19].entered_at).to eq(Time.at(19))

    positions = @position_repository.retrieve_positions(
      nil, entered_at: :desc)

    expect(positions.size).to eq(20)
    expect(positions[0].backtest_id).to eq(nil)
    expect(positions[0].entered_at).to eq(Time.at(99))
    expect(positions[19].backtest_id).to eq(nil)
    expect(positions[19].entered_at).to eq(Time.at(80))

    positions = @position_repository.retrieve_positions(
      nil, { entered_at: :desc }, 10, 30)

    expect(positions.size).to eq(30)
    expect(positions[0].backtest_id).to eq(nil)
    expect(positions[0].entered_at).to eq(Time.at(89))
    expect(positions[29].backtest_id).to eq(nil)
    expect(positions[29].entered_at).to eq(Time.at(60))

    positions = @position_repository.retrieve_positions(
      nil, { entered_at: :asc }, 10, 30)

    expect(positions.size).to eq(30)
    expect(positions[0].backtest_id).to eq(nil)
    expect(positions[0].entered_at).to eq(Time.at(10))
    expect(positions[29].backtest_id).to eq(nil)
    expect(positions[29].entered_at).to eq(Time.at(39))

    positions = @position_repository.retrieve_positions(@test1._id)

    expect(positions.size).to eq(20)
    expect(positions[0].backtest_id).to eq(@test1._id)
    expect(positions[0].entered_at).to eq(Time.at(0))
    expect(positions[19].backtest_id).to eq(@test1._id)
    expect(positions[19].entered_at).to eq(Time.at(19))

    positions = @position_repository.retrieve_positions(
      @test1._id, { exited_at: :desc }, 10, 30)

    expect(positions.size).to eq(30)
    expect(positions[0].backtest_id).to eq(@test1._id)
    expect(positions[0].entered_at).to eq(Time.at(39))
    expect(positions[29].backtest_id).to eq(@test1._id)
    expect(positions[29].entered_at).to eq(Time.at(10))

    positions = @position_repository.retrieve_positions(@test3._id)

    expect(positions.size).to eq(0)
  end

  it 'アクティブなRMTの建玉を取得できる' do
    positions = @position_repository.retrieve_living_positions_of_rmt

    expect(positions.size).to eq(50)
    expect(positions[0].backtest_id).to eq(nil)
    expect(positions[0].entered_at).to eq(Time.at(50))
    expect(positions[0].exited_at).to eq(nil)
    expect(positions[49].backtest_id).to eq(nil)
    expect(positions[49].entered_at).to eq(Time.at(99))
    expect(positions[49].exited_at).to eq(nil)
  end

  it '不要になったバックテストの建玉を削除できる' do
    positions = @position_repository.retrieve_positions(@test1._id)
    expect(positions.size).to eq(20)
    positions = @position_repository.retrieve_positions(@test2._id)
    expect(positions.size).to eq(20)

    @position_repository.delete_all_positions_of_backtest(@test1._id)

    positions = @position_repository.retrieve_positions(@test1._id)
    expect(positions.size).to eq(0)
    positions = @position_repository.retrieve_positions(@test2._id)
    expect(positions.size).to eq(20)
  end

  it '決済済みになったRMTの建玉を削除できる'  do
    positions = @position_repository.retrieve_positions
    expect(positions.size).to eq(20)

    @position_repository.delete_closed_positions_of_rmt(Time.at(40))

    positions = @position_repository.retrieve_positions
    expect(positions.size).to eq(20)
    expect(positions[0].backtest_id).to eq(nil)
    expect(positions[0].entered_at).to eq(Time.at(40))
    expect(positions[0].exited_at).to eq(Time.at(40))
    expect(positions[19].backtest_id).to eq(nil)
    expect(positions[19].entered_at).to eq(Time.at(59))
    expect(positions[19].exited_at).to eq(nil)

    @position_repository.delete_closed_positions_of_rmt(Time.at(60))

    positions = @position_repository.retrieve_positions
    expect(positions.size).to eq(20)
    expect(positions[0].backtest_id).to eq(nil)
    expect(positions[0].entered_at).to eq(Time.at(50))
    expect(positions[0].exited_at).to eq(nil)
    expect(positions[19].backtest_id).to eq(nil)
    expect(positions[19].entered_at).to eq(Time.at(69))
    expect(positions[19].exited_at).to eq(nil)
  end
end
