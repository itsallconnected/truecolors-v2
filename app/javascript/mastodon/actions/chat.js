import api from '../api';

export const CHAT_MOUNT_CONVERSE = 'CHAT_MOUNT_CONVERSE';
export const CHAT_MOUNT_CONVERSE_SUCCESS = 'CHAT_MOUNT_CONVERSE_SUCCESS';
export const CHAT_MOUNT_CONVERSE_FAIL = 'CHAT_MOUNT_CONVERSE_FAIL';
export const CHAT_UNMOUNT_CONVERSE = 'CHAT_UNMOUNT_CONVERSE';
export const CHAT_TOGGLE_SETTING = 'CHAT_TOGGLE_SETTING';

/**
 * Initialize and mount the Converse.js client with XMPP credentials
 * This action fetches the credentials from Redux state and configures the chat client
 * with secure OMEMO encryption
 * @returns {function} Thunk action that dispatches CHAT_MOUNT_CONVERSE actions
 */
export function mountConverse() {
  return (dispatch, getState) => {
    dispatch({ type: CHAT_MOUNT_CONVERSE });
    
    return new Promise((resolve, reject) => {
      try {
        const state = getState();
        const xmppCredentials = state.getIn(['xmpp', 'credentials']);
        
        if (!xmppCredentials) {
          throw new Error('XMPP credentials not found');
        }
        
        if (!window.converse) {
          throw new Error('Converse.js not loaded');
        }
        
        const jid = xmppCredentials.get('jid');
        const password = xmppCredentials.get('password');
        const boshUrl = xmppCredentials.get('bosh_url');
        const websocketUrl = xmppCredentials.get('websocket_url');
        
        // Get chat settings from local storage or use defaults
        const settings = state.getIn(['chat', 'settings']);
        const encryptByDefault = settings ? settings.get('encrypt_by_default') : true;
        const showRead = settings ? settings.get('show_read') : true;
        
        // Initialize Converse.js with secure settings
        window.converse.initialize({
          authentication: 'login',
          auto_login: true,
          allow_registration: false,
          allow_contact_requests: true,
          allow_contact_removal: true,
          allow_message_corrections: true,
          jid: jid,
          password: password,
          websocket_url: websocketUrl,
          bosh_service_url: boshUrl,
          message_archiving: 'always',
          message_carbons: true,
          view_mode: 'fullscreen',
          show_send_button: true,
          show_toolbar: true,
          sticky_controlbox: true,
          visible_toolbar_buttons: {
            call: false,
            spoiler: true,
            emoji: true,
            toggle_occupants: true
          },
          omemo_default: encryptByDefault,
          locales_url: '/converse-assets/locales/',
          whitelisted_plugins: [
            'omemo',
            'converse-emoji',
            'converse-muc',
            'converse-muc-views',
            'converse-chatboxes',
            'converse-control-box'
          ],
          show_message_receipts: showRead,
          persistent_store: 'IndexedDB',
          trusted: true,
          root: document.getElementById('converse-container'),
          loglevel: process.env.NODE_ENV === 'development' ? 'debug' : 'error',
        });
        
        // Handle successful initialization
        dispatch({
          type: CHAT_MOUNT_CONVERSE_SUCCESS,
        });
        
        resolve();
      } catch (error) {
        console.error('Error mounting Converse.js:', error);
        
        dispatch({
          type: CHAT_MOUNT_CONVERSE_FAIL,
          error: error.message || 'Failed to mount Converse.js',
        });
        
        reject(error);
      }
    });
  };
}

/**
 * Unmount and disconnect the Converse.js client
 * This should be called when navigating away from the chat view
 * to properly clean up resources
 * @returns {object} Action to unmount Converse.js
 */
export function unmountConverse() {
  // Disconnect from XMPP server if Converse.js is loaded
  if (window.converse && typeof window.converse.disconnect === 'function') {
    window.converse.disconnect();
  }
  
  return {
    type: CHAT_UNMOUNT_CONVERSE,
  };
}

/**
 * Toggle a chat setting and save it to the server
 * @param {string} setting - The setting name to toggle
 * @param {boolean} value - The new value for the setting
 * @returns {function} Thunk action that dispatches CHAT_TOGGLE_SETTING
 */
export function toggleChatSetting(setting, value) {
  return (dispatch) => {
    // Save setting to server
    return api().patch('/api/v1/preferences', {
      data: { [`chat_${setting}`]: value },
    }).then(() => {
      dispatch({
        type: CHAT_TOGGLE_SETTING,
        setting,
        value,
      });
      
      // If setting affects Converse.js and it's initialized, update it
      if (window.converse && window.converse.user) {
        if (setting === 'encrypt_by_default') {
          window.converse.user.settings.omemo_default = value;
        } else if (setting === 'show_read') {
          window.converse.user.settings.show_message_receipts = value;
        }
      }
    });
  };
} 