require 'rails_helper'

module AppStore
  module V1
    class Base
      # Instantiate this class here as the BaseFormObject assumes a class with this name exists
      attr_reader :no_op
    end
  end
end

RSpec.describe Steps::BaseFormObject do
  describe '.build' do
    let(:favourite_meal_form) do
      Class.new(Steps::BaseFormObject) do
        attribute :favourite_meal, :string
      end
    end

    let(:foo_bar_record) do
      Class.new(ApplicationRecord) do
        attr_accessor :favourite_meal

        def self.load_schema! = @columns_hash = {}
      end
    end

    before do
      stub_const('FavouriteMealForm', favourite_meal_form)
      stub_const('FooBarRecord', foo_bar_record)
    end

    context 'for an non active record argument' do
      it 'raises an error' do
        expect do
          FavouriteMealForm.build(:foobar)
        end.to raise_exception(ArgumentError)
      end
    end

    context 'for an active record argument' do
      let(:record) { FooBarRecord.new(favourite_meal: 'pizza') }

      before do
        allow(record).to receive(:attribute_names).and_return(['favourite_meal'])
      end

      it 'instantiates the form object using the declared attributes' do
        form = FavouriteMealForm.build(record)

        expect(form.favourite_meal).to eq('pizza')
        expect(form.application).to eq(record)
        expect(form.record).to eq(record)
      end
    end
  end

  describe 'changed?' do
    let(:klass) do
      Class.new(described_class) do
        attribute :name
      end
    end

    let(:record) { { 'name' => 'James' } }
    let(:form) { klass.new(:record => record, 'name' => name) }

    context 'when attributes have not changed' do
      let(:name) { 'James' }

      it { expect(form).not_to be_changed }
    end

    context 'when attributes have changed' do
      let(:name) { 'Jim' }

      it { expect(form).to be_changed }
    end
  end

  describe 'attribute_changed?' do
    before do
      stub_const('NameForm', form_klass)
      stub_const('NameRecord', record_klass)
    end

    let(:form_klass) do
      Class.new(described_class) do
        attribute :first_name
      end
    end

    let(:record_klass) do
      Class.new(ApplicationRecord) do
        attr_accessor :first_name

        def self.load_schema! = @columns_hash = {}
      end
    end

    let(:record) { record_klass.new('first_name' => 'James') }
    let(:form) { form_klass.new(:record => record, 'first_name' => first_name) }

    context 'when the attribute has not changed' do
      let(:first_name) { 'James' }

      it { expect(form.attribute_changed?(:first_name)).to be false }
    end

    context 'when attribute has changed' do
      let(:first_name) { 'Jim' }

      it { expect(form.attribute_changed?(:first_name)).to be true }
    end
  end

  describe '#save' do
    before do
      allow(subject).to receive(:valid?).and_return(is_valid)
    end

    context 'for a valid form' do
      let(:is_valid) { true }

      it 'calls persist!' do
        expect(subject).to receive(:persist!)
        subject.save
      end
    end

    context 'for an invalid form' do
      let(:is_valid) { false }

      it 'does not call persist!' do
        expect(subject).not_to receive(:persist!)
        subject.save
      end

      it { expect(subject.save).to be(false) }
    end
  end

  describe '#save!' do
    context 'when raising exceptions' do
      it {
        expect(subject).to receive(:persist!).and_raise(NoMethodError)
        expect(subject.save!).to be(false)
      }
    end

    context 'when there are no exceptions' do
      it {
        expect(subject).to receive(:persist!).and_return(true)
        expect(subject.save!).to be(true)
      }
    end
  end

  describe '#persisted?' do
    it { expect(subject.persisted?).to be(false) }
  end

  describe '#new_record?' do
    it { expect(subject.new_record?).to be(true) }
  end

  describe '#to_key' do
    it { expect(subject.to_key).to be_nil }
  end

  describe '[]' do
    let(:record) { double('Record') }

    before do
      subject.record = record
    end

    it 'read the attribute directly without using the method' do
      expect(subject[:record]).to eq(record)
    end
  end

  describe '[]=' do
    let(:record) { double('Record') }

    it 'assigns the attribute directly without using the method' do
      subject[:record] = record
      expect(subject.record).to eq(record)
    end
  end
end
