import { apiCreate, apiUpdate } from 'truecolors/api/lists';
import type { List } from 'truecolors/models/list';
import { createDataLoadingThunk } from 'truecolors/store/typed_functions';

export const createList = createDataLoadingThunk(
  'list/create',
  (list: Partial<List>) => apiCreate(list),
);

export const updateList = createDataLoadingThunk(
  'list/update',
  (list: Partial<List>) => apiUpdate(list),
);
