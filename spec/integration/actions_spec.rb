require 'spec_helper'

describe 'Actions' do
  before(:each) do
    Triggerable::Engine.clear
    TestTask.destroy_all
  end

  class CreateFollowUp < Triggerable::Actions::Action
    def run_for! task, rule_name
      TestTask.create kind: 'follow up'
    end
  end

  it 'custom action' do
    TestTask.trigger on: :after_update,
                     if: { status: 'solved' },
                     do: :create_follow_up

    task = TestTask.create
    expect(TestTask.count).to eq(1)

    task.update_attributes status: 'solved'
    expect(TestTask.count).to eq(2)
    expect(TestTask.all.last.kind).to eq('follow up')
  end

  it 'custom action chain' do
    TestTask.trigger on: :after_update,
                     if: { status: 'solved' },
                     do: [:create_follow_up, :create_follow_up]

    task = TestTask.create
    expect(TestTask.count).to eq(1)

    task.update_attributes status: 'solved'
    expect(TestTask.count).to eq(3)
    expect(TestTask.all[-2].kind).to eq('follow up')
    expect(TestTask.all.last.kind).to eq('follow up')
  end

  describe 'when Triggerable is disabled' do
    before do
      TestTask.trigger on: :after_create,
                       if: { status: 'solved' },
                       do: :create_follow_up
    end

    after { Triggerable.enable! }

    it 'it does not run actions' do
      expect {
        TestTask.create status: 'solved'
      }.to change(TestTask, :count).by(2)

      Triggerable.disable!

      expect {
        TestTask.create status: 'solved'
      }.to change(TestTask, :count).by(1)
    end
  end
end
