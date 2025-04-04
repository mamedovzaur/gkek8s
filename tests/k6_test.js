import http from 'k6/http';
import { sleep } from 'k6';
export const options = {
  vus: 100,
  duration: '300s',
};

export default function () {
  http.get('http://webapp.loc');
  sleep(1);
}