import { Map as ImmutableMap, fromJS } from 'immutable';
import {
  XMPP_FETCH_CREDENTIALS_REQUEST,
  XMPP_FETCH_CREDENTIALS_SUCCESS,
  XMPP_FETCH_CREDENTIALS_FAIL,
  XMPP_REGENERATE_CREDENTIALS_SUCCESS,
} from '../actions/xmpp';

const initialState = ImmutableMap({
  loading: false,
  error: null,
  credentials: null,
});

/**
 * Reducer for handling XMPP-related state
 * Manages XMPP credentials and connection state
 * 
 * @param {ImmutableMap} state - Current state
 * @param {Object} action - Redux action
 * @returns {ImmutableMap} New state
 */
export default function xmpp(state = initialState, action) {
  switch(action.type) {
    case XMPP_FETCH_CREDENTIALS_REQUEST:
      return state.set('loading', true);
    
    case XMPP_FETCH_CREDENTIALS_SUCCESS:
      return state
        .set('loading', false)
        .set('error', null)
        .set('credentials', fromJS(action.credentials));
    
    case XMPP_FETCH_CREDENTIALS_FAIL:
      return state
        .set('loading', false)
        .set('error', action.error);
    
    case XMPP_REGENERATE_CREDENTIALS_SUCCESS:
      return state
        .set('credentials', fromJS(action.credentials));
    
    default:
      return state;
  }
} 