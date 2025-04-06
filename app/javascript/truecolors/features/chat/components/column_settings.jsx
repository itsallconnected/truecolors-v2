import PropTypes from 'prop-types';
import React from 'react';
import { defineMessages, injectIntl, FormattedMessage } from 'react-intl';
import ImmutablePureComponent from 'react-immutable-pure-component';
import SettingToggle from '../../notifications/components/setting_toggle';

const messages = defineMessages({
  settings: { id: 'chat.settings', defaultMessage: 'Chat settings' },
  encryptByDefault: { id: 'chat.settings.encrypt_by_default', defaultMessage: 'Enable OMEMO encryption by default' },
  notifications: { id: 'chat.settings.notifications', defaultMessage: 'Chat notifications' },
  showRead: { id: 'chat.settings.show_read', defaultMessage: 'Show read receipts' },
});

/**
 * ColumnSettings component for Chat feature
 * Provides settings for OMEMO encryption, notifications and read receipts
 */
export default @injectIntl
class ColumnSettings extends ImmutablePureComponent {
  static propTypes = {
    settings: PropTypes.object.isRequired,
    onChange: PropTypes.func.isRequired,
    intl: PropTypes.object.isRequired,
  };

  handleChange = (key, checked) => {
    this.props.onChange({ [key]: checked });
  };

  render() {
    const { settings, intl } = this.props;

    return (
      <div className='column-settings__section'>
        <div className='column-settings__content'>
          <div className='column-settings__header'>
            <h3><FormattedMessage id='chat.settings' defaultMessage='Chat settings' /></h3>
          </div>

          <div className='column-settings__row'>
            <SettingToggle
              prefix='chat_settings'
              settings={settings}
              settingPath='encrypt_by_default'
              onChange={this.handleChange}
              label={intl.formatMessage(messages.encryptByDefault)}
            />
          </div>

          <div className='column-settings__row'>
            <SettingToggle
              prefix='chat_settings'
              settings={settings}
              settingPath='notifications'
              onChange={this.handleChange}
              label={intl.formatMessage(messages.notifications)}
            />
          </div>

          <div className='column-settings__row'>
            <SettingToggle
              prefix='chat_settings'
              settings={settings}
              settingPath='show_read'
              onChange={this.handleChange}
              label={intl.formatMessage(messages.showRead)}
            />
          </div>
        </div>
      </div>
    );
  }
} 