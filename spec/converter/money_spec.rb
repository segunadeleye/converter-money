require 'spec_helper'

module Converter
  describe Money do

    describe 'validations' do
      shared_examples 'unconfigured money' do
        it { expect(Money.base_currency).to be_nil }
        it { expect(Money.other_currencies).to be_nil }
      end

      context '.conversion_rates' do
        it { expect { Money.conversion_rates('EUR', {}) }.to raise_error(ArgumentError, 'Empty hash') }
        it { expect { Money.conversion_rates('EUR', 300) }.to raise_error(ArgumentError, 'Invalid Options: options must be a hash') }

        it_should_behave_like 'unconfigured money'
      end

      context 'when configuration is not set' do
        describe '#initialize' do
          it_should_behave_like 'unconfigured money'

          it 'raises ConfigurationError exception' do
            expect { Money.new(50, 'EUR') }.to raise_error(Money::ConfigurationError)
            expect(Money.base_currency).to be_nil
            expect(Money.other_currencies).to be_nil
          end
        end
      end
    end

    describe 'when configuration is set' do
      let(:money) { Money.new(50, 'EUR') }

      before(:all) do
        Money.conversion_rates('EUR', {
          'USD' => 1.11,
          'Bitcoin' => 0.0047
        })
      end

      describe '.conversion_rates' do
        it 'sets configuration for conversion rates' do
          expect(Money.base_currency).to eq('EUR')
          expect(Money.other_currencies).to eq({
            'USD' => 1.11,
            'Bitcoin' => 0.0047
          })
        end
      end

      describe '#initialize' do
        it { expect(money).to be_an_instance_of Money }
      end

      describe '#amount' do
        it { expect(money.amount).to eq(50) }
      end

      describe '#currency' do
        it { expect(money.currency).to eq('EUR') }
      end

      describe '#inspect' do
        it { expect(money.inspect).to eq('50.00 EUR') }
      end

      describe '#convert_to' do
        let(:usd_money) { money.convert_to('USD') }
        let(:bitcoin_money) { money.convert_to('Bitcoin') }
        let(:same_money) { money.convert_to('EUR') }

        it 'returns instances of Money' do
          expect(usd_money).to be_an_instance_of Money
          expect(bitcoin_money).to be_an_instance_of Money
          expect(same_money).to be_an_instance_of Money
        end

        context 'conversion from base currency to other currencies' do
          it { expect(usd_money.inspect).to eq('55.50 USD') }
          it { expect(bitcoin_money.inspect).to eq('0.24 Bitcoin') }
        end

        context 'conversion to the same currency' do
          it 'returns same objects' do
            expect(money.convert_to('EUR')).to equal(money)
            expect(usd_money.convert_to('USD')).to equal(usd_money)
            expect(bitcoin_money.convert_to('Bitcoin')).to equal(bitcoin_money)
          end

          it { expect(money.convert_to('EUR').inspect).to eq('50.00 EUR') }
          it { expect(usd_money.convert_to('USD').inspect).to eq('55.50 USD') }
          it { expect(bitcoin_money.convert_to('Bitcoin').inspect).to eq('0.24 Bitcoin') }
        end
      end

      describe 'validations' do
        context '#initialize' do
          it { expect{ Money.new('50', 'EUR') }.to raise_error(ArgumentError, 'Invalid Amount: amount must be a number') }
          it { expect{ Money.new(50, 'NGN') }.to raise_error(ArgumentError, 'Invalid Currency: currency does not exist in configuration') }
        end

        context '#convert_to' do
          it { expect { money.convert_to('NGN') }.to raise_error(ArgumentError, 'Invalid Currency: currency does not exist in configuration') }
        end
      end
    end

  end
end
