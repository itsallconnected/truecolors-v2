# frozen_string_literal: true

# == Schema Information
#
# Table name: xmpp_credentials
#
# id           :bigint(8)        not null, primary key
# user_id      :bigint(8)        not null, foreign key
# jid          :string           not null
# password     :string           not null
# created_at   :datetime         not null
# updated_at   :datetime         not null
#
# Indexes
#
#  index_xmpp_credentials_on_user_id  (user_id)
#  index_xmpp_credentials_on_jid      (jid) UNIQUE
#  index_xmpp_credentials_on_user_id_and_jid (user_id, jid) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#

class XmppCredential < ApplicationRecord
  # The XmppCredential model manages XMPP/Jabber credentials for users
  # to enable secure chat functionality with OMEMO encryption
  
  belongs_to :user
  
  # Generate a secure random password for XMPP authentication
  before_validation :ensure_password, on: :create
  before_validation :ensure_jid, on: :create
  
  validates :jid, presence: true, uniqueness: true
  validates :password, presence: true
  
  # Encrypts the password in the database for additional security
  encrypts :password
  
  private
  
  def ensure_password
    self.password = SecureRandom.base58(24) if password.blank?
  end
  
  def ensure_jid
    self.jid = "#{user.account.username}@#{ENV['XMPP_DOMAIN']}" if jid.blank? && user&.account&.username.present?
  end
end 