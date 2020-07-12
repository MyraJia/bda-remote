require 'test_helper'

class CompetitionTest < ActiveSupport::TestCase
  context "associations" do
    should have_many(:records)
    should have_many(:heats)
    should have_many(:vessels)
  end

  context "validations" do
    should validate_presence_of(:name)
    should validate_presence_of(:stage)
    should validate_presence_of(:status)
  end

  test "newly created competition should assign zero stage" do
    competition = Competition.new
    assert_not competition.nil?, "nil competition"
    assert_not competition.stage.nil?, "nil stage"
    assert_equal competition.stage, 0, "stage invalid"
  end
end
