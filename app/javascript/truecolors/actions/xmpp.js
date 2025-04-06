import api from '../api';
import { defineMessages } from 'react-intl';
import { showAlertForError } from './alerts';

export const XMPP_FETCH_CREDENTIALS_REQUEST = 'XMPP_FETCH_CREDENTIALS_REQUEST';
export const XMPP_FETCH_CREDENTIALS_SUCCESS = 'XMPP_FETCH_CREDENTIALS_SUCCESS';
export const XMPP_FETCH_CREDENTIALS_FAIL = 'XMPP_FETCH_CREDENTIALS_FAIL';
export const XMPP_REGENERATE_CREDENTIALS_REQUEST = 'XMPP_REGENERATE_CREDENTIALS_REQUEST';
export const XMPP_REGENERATE_CREDENTIALS_SUCCESS = 'XMPP_REGENERATE_CREDENTIALS_SUCCESS';
export const XMPP_REGENERATE_CREDENTIALS_FAIL = 'XMPP_REGENERATE_CREDENTIALS_FAIL';

const messages = defineMessages({
  regenerate_success: { id: 'xmpp.regenerate_success', defaultMessage: 'XMPP credentials successfully regenerated. You will need to reconnect chat sessions.' },
  regenerate_error: { id: 'xmpp.regenerate_error', defaultMessage: 'Failed to regenerate XMPP credentials. Please try again later.' },
});

/**
 * Fetch XMPP credentials for the current user
 * These credentials are used to authenticate with the XMPP server
 * @returns {function} Thunk action that dispatches XMPP_FETCH_CREDENTIALS actions
 */
export function fetchXmppCredentials() {
  return (dispatch) => {
    dispatch({ type: XMPP_FETCH_CREDENTIALS_REQUEST });
    
    return api().get('/api/v1/xmpp/credentials').then(response => {
      dispatch({
        type: XMPP_FETCH_CREDENTIALS_SUCCESS,
        credentials: response.data,
      });
      
      return Promise.resolve(response.data);
    }).catch(error => {
      dispatch({
        type: XMPP_FETCH_CREDENTIALS_FAIL,
        error: error,
      });
      
      dispatch(showAlertForError(error));
      return Promise.reject(error);
    });
  };
}

/**
 * Regenerate XMPP credentials for the current user
 * This creates a new password for the user's XMPP account,
 * requiring re-authentication in all connected clients
 * @returns {function} Thunk action that dispatches XMPP_REGENERATE_CREDENTIALS actions
 */
export function regenerateXmppCredentials() {
  return (dispatch, getState) => {
    dispatch({ type: XMPP_REGENERATE_CREDENTIALS_REQUEST });
    
    return api().post('/api/v1/xmpp/regenerate').then(response => {
      dispatch({
        type: XMPP_REGENERATE_CREDENTIALS_SUCCESS,
        credentials: response.data,
      });
      
      // Show success message
      dispatch(showAlert('success', messages.regenerate_success));
      
      return Promise.resolve(response.data);
    }).catch(error => {
      dispatch({
        type: XMPP_REGENERATE_CREDENTIALS_FAIL,
        error: error,
      });
      
      // Show error message
      dispatch(showAlert('error', messages.regenerate_error));
      
      return Promise.reject(error);
    });
  };
} 