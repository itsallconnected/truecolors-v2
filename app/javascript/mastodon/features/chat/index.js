import React from 'react';
import { connect } from 'react-redux';
import { defineMessages, injectIntl } from 'react-intl';
import PropTypes from 'prop-types';
import Column from '../ui/components/column';
import ColumnHeader from '../../components/column_header';
import { fetchXmppCredentials } from '../../actions/xmpp';
import { mountConverse, unmountConverse } from '../../actions/chat';
import LoadingIndicator from '../../components/loading_indicator';
import { openModal } from '../../actions/modal';
import ChatSettingsContainer from './containers/column_settings_container';

const messages = defineMessages({
  title: { id: 'column.chat', defaultMessage: 'Chat' },
  empty: { id: 'chat.empty', defaultMessage: "You don't have any chats yet. Start a new conversation by clicking the compose button." },
  loading: { id: 'chat.loading', defaultMessage: 'Loading chat...' },
  error: { id: 'chat.error', defaultMessage: 'Error loading chat. The XMPP server may be unavailable.' },
  settings: { id: 'chat.settings.title', defaultMessage: 'Chat settings' },
});

/**
 * ChatTimeline component provides a secure chat interface using XMPP/Jabber with OMEMO encryption
 * It integrates with Converse.js for the chat functionality and requires an XMPP server
 */
export default @connect()
@injectIntl
class ChatTimeline extends React.PureComponent {
  static contextTypes = {
    router: PropTypes.object,
  };

  static propTypes = {
    dispatch: PropTypes.func.isRequired,
    intl: PropTypes.object.isRequired,
    multiColumn: PropTypes.bool,
  };

  state = {
    loading: true,
    error: false,
    converseLoaded: false,
  };

  componentDidMount() {
    const { dispatch } = this.props;
    
    // Step 1: Fetch XMPP credentials
    dispatch(fetchXmppCredentials()).then(() => {
      // Step 2: Load Converse.js scripts and stylesheets
      this.loadConverseAssets().then(() => {
        // Step 3: Initialize and mount Converse.js
        dispatch(mountConverse())
          .then(() => {
            this.setState({ 
              loading: false,
              converseLoaded: true,
            });
          })
          .catch((error) => {
            console.error('Error mounting Converse.js:', error);
            this.setState({ 
              loading: false, 
              error: true 
            });
          });
      }).catch((error) => {
        console.error('Error loading Converse.js assets:', error);
        this.setState({ 
          loading: false, 
          error: true 
        });
      });
    }).catch((error) => {
      console.error('Error fetching XMPP credentials:', error);
      this.setState({ 
        loading: false, 
        error: true 
      });
    });
  }

  componentWillUnmount() {
    const { dispatch } = this.props;
    if (this.state.converseLoaded) {
      dispatch(unmountConverse());
    }
  }

  loadConverseAssets = () => {
    return new Promise((resolve, reject) => {
      try {
        if (window.converse) {
          return resolve();
        }
        
        // Load Converse.js script
        const script = document.createElement('script');
        script.src = '/converse-assets/converse.min.js';
        script.async = true;
        
        // Load Converse.js stylesheet
        const link = document.createElement('link');
        link.rel = 'stylesheet';
        link.href = '/converse-assets/converse.min.css';
        
        // Add to document head
        document.head.appendChild(link);
        document.head.appendChild(script);
        
        // Wait for script to load
        script.onload = () => resolve();
        script.onerror = (error) => reject(error);
      } catch (error) {
        reject(error);
      }
    });
  };

  handleHeaderClick = () => {
    this.column.scrollTop();
  };

  handleOpenSettings = () => {
    const { dispatch, intl } = this.props;
    
    dispatch(openModal('CHAT_SETTINGS', {
      title: intl.formatMessage(messages.settings),
    }));
  };

  setRef = (c) => {
    this.column = c;
  };

  render() {
    const { intl, multiColumn } = this.props;
    const { loading, error } = this.state;

    return (
      <Column bindToDocument={!multiColumn} ref={this.setRef}>
        <ColumnHeader
          icon='comment'
          title={intl.formatMessage(messages.title)}
          onClick={this.handleHeaderClick}
          showBackButton
          multiColumn={multiColumn}
          onSettings={this.handleOpenSettings}
        />
        
        <div className='chat-timeline__container'>
          {loading && (
            <div className='chat-timeline__loading'>
              <LoadingIndicator />
              <span>{intl.formatMessage(messages.loading)}</span>
            </div>
          )}
          
          {error && (
            <div className='chat-timeline__error'>
              <span>{intl.formatMessage(messages.error)}</span>
            </div>
          )}
          
          <div id='converse-container' className='chat-timeline__converse'></div>
        </div>
      </Column>
    );
  }
} 