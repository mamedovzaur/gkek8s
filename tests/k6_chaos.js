import http from 'k6/http';
import { sleep } from 'k6';
export const options = {
  vus: 1000,
  duration: '300s',
};

export default function () {
  http.get('http://webapp.loc/chaos');
  sleep(1);
}