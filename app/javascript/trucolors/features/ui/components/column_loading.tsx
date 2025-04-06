import { Column } from 'truecolors/components/column';
import { ColumnHeader } from 'truecolors/components/column_header';
import type { Props as ColumnHeaderProps } from 'truecolors/components/column_header';

export const ColumnLoading: React.FC<ColumnHeaderProps> = (otherProps) => (
  <Column>
    <ColumnHeader {...otherProps} />
    <div className='scrollable' />
  </Column>
);
